import Foundation
import AVFoundation

public class AudioConverter {
    public static func convert(
        sourceURL: URL,
        targetFormat: TargetFormat,
        outputFolder: URL? = nil,
        overwrite: Bool = false,
        onProgress: @escaping (Double) -> Void
    ) async throws -> (outputURL: URL, outputSize: Int64, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let targetExt = targetFormat.fileExtension
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let targetDirectory = outputFolder ?? sourceURL.deletingLastPathComponent()
        
        var destinationURL = targetDirectory.appendingPathComponent("\(baseName).\(targetExt)")
        
        if !overwrite && FileManager.default.fileExists(atPath: destinationURL.path) {
            var counter = 1
            while FileManager.default.fileExists(atPath: destinationURL.path) {
                destinationURL = targetDirectory.appendingPathComponent("\(baseName)_\(counter).\(targetExt)")
                counter += 1
            }
        }
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        
        // Native AVFoundation for M4A / AAC
        if targetFormat == .m4a {
            let asset = AVURLAsset(url: sourceURL)
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                throw VideoConverterError.unsupportedAsset
            }
            if #available(macOS 15.0, *) {
                do {
                    try await exportSession.export(to: destinationURL, as: .m4a)
                    await MainActor.run { onProgress(1.0) }
                    let duration = CFAbsoluteTimeGetCurrent() - startTime
                    let outputSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.int64Value ?? 0
                    return (destinationURL, outputSize, duration)
                } catch {
                    throw VideoConverterError.exportSessionFailed(error.localizedDescription)
                }
            } else {
                exportSession.outputURL = destinationURL
                exportSession.outputFileType = .m4a
                
                let timer = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        let p = Double(exportSession.progress)
                        await MainActor.run { onProgress(p) }
                    }
                }
                
                await exportSession.export()
                timer.cancel()
                
                if exportSession.status == .completed {
                    await MainActor.run { onProgress(1.0) }
                    let duration = CFAbsoluteTimeGetCurrent() - startTime
                    let outputSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.int64Value ?? 0
                    return (destinationURL, outputSize, duration)
                } else {
                    throw VideoConverterError.exportSessionFailed(exportSession.error?.localizedDescription ?? "Ses dışa aktarma hatası")
                }
            }
        }
        
        // Fallback to ffmpeg for MP3, WAV, etc.
        if let ffmpegPath = VideoConverter.findFFmpeg() {
            return try await withCheckedThrowingContinuation { continuation in
                let process = Process()
                process.executableURL = URL(fileURLWithPath: ffmpegPath)
                
                var args = ["-y", "-i", sourceURL.path, "-vn"]
                if targetFormat == .mp3 {
                    args += ["-c:a", "libmp3lame", "-b:a", "320k"]
                } else if targetFormat == .wav {
                    args += ["-c:a", "pcm_s16le"]
                }
                args.append(destinationURL.path)
                
                process.arguments = args
                
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    process.waitUntilExit()
                    if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: destinationURL.path) {
                        let duration = CFAbsoluteTimeGetCurrent() - startTime
                        let outputSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.int64Value ?? 0
                        DispatchQueue.main.async { onProgress(1.0) }
                        continuation.resume(returning: (destinationURL, outputSize, duration))
                    } else {
                        continuation.resume(throwing: VideoConverterError.exportSessionFailed("Ses dönüştürülemedi."))
                    }
                }
            }
        }
        
        throw VideoConverterError.exportSessionFailed("Bu format için ffmpeg gereklidir.")
    }
}
