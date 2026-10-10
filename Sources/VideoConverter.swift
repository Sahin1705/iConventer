import Foundation
import AVFoundation

public enum VideoConverterError: LocalizedError {
    case unsupportedAsset
    case exportSessionFailed(String)
    case cancelled
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedAsset:
            return "Video dosyası açılamadı veya desteklenmeyen format."
        case .exportSessionFailed(let msg):
            return "Dışa aktarma başarısız: \(msg)"
        case .cancelled:
            return "Dönüştürme iptal edildi."
        case .unknown:
            return "Bilinmeyen bir hata oluştu."
        }
    }
}

public class VideoConverter {
    public static func findFFmpeg() -> String? {
        let paths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        for path in paths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }
    
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
        
        let ffmpeg = findFFmpeg()
        
        // 1. Ultra-Fast Stream Passthrough (Remuxing) Mode (0.2s - 0.5s for 100+ MB!)
        if (targetFormat == .mp4_remux || targetFormat == .mov_remux), let ffmpegPath = ffmpeg {
            do {
                return try await convertRemux(
                    ffmpegPath: ffmpegPath,
                    sourceURL: sourceURL,
                    destinationURL: destinationURL,
                    startTime: startTime,
                    onProgress: onProgress
                )
            } catch {
                // If remux failed (e.g. incompatible stream for mp4 container), gracefully fallback to M5 hardware encode!
                print("Remux failed or incompatible, falling back to M5 Hardware Re-encode...")
            }
        }
        
        // 2. Hardware Accelerated VideoToolbox Conversion with Real-Time Progress
        if let ffmpegPath = ffmpeg {
            return try await convertWithFFmpeg(
                ffmpegPath: ffmpegPath,
                sourceURL: sourceURL,
                destinationURL: destinationURL,
                targetFormat: targetFormat,
                startTime: startTime,
                onProgress: onProgress
            )
        } else {
            // Native AVFoundation Fallback
            return try await convertWithAVFoundation(
                sourceURL: sourceURL,
                destinationURL: destinationURL,
                targetFormat: targetFormat,
                startTime: startTime,
                onProgress: onProgress
            )
        }
    }
    
    // MARK: - Ultra-Fast Stream Copy Remux (0.2s)
    private static func convertRemux(
        ffmpegPath: String,
        sourceURL: URL,
        destinationURL: URL,
        startTime: CFAbsoluteTime,
        onProgress: @escaping (Double) -> Void
    ) async throws -> (outputURL: URL, outputSize: Int64, duration: TimeInterval) {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ffmpegPath)
            process.arguments = [
                "-nostdin",
                "-y",
                "-i", sourceURL.path,
                "-c", "copy",
                "-movflags", "+faststart",
                destinationURL.path
            ]
            
            process.standardOutput = FileHandle.nullDevice
            let errPipe = Pipe()
            process.standardError = errPipe
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }
            
            DispatchQueue.main.async { onProgress(0.25) }
            
            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()
                
                if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: destinationURL.path) {
                    let duration = CFAbsoluteTimeGetCurrent() - startTime
                    let outputSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.int64Value ?? 0
                    DispatchQueue.main.async {
                        onProgress(1.0)
                        continuation.resume(returning: (destinationURL, outputSize, duration))
                    }
                } else {
                    continuation.resume(throwing: VideoConverterError.exportSessionFailed("Remux uyumsuzluğu."))
                }
            }
        }
    }
    
    // MARK: - FFmpeg with VideoToolbox Hardware Encoder + Real-Time Live Progress
    private static func convertWithFFmpeg(
        ffmpegPath: String,
        sourceURL: URL,
        destinationURL: URL,
        targetFormat: TargetFormat,
        startTime: CFAbsoluteTime,
        onProgress: @escaping (Double) -> Void
    ) async throws -> (outputURL: URL, outputSize: Int64, duration: TimeInterval) {
        // Read input duration in microseconds
        let asset = AVURLAsset(url: sourceURL)
        let durationCM = try? await asset.load(.duration)
        let totalSeconds = durationCM?.seconds ?? 0
        let totalMicroseconds = (totalSeconds > 0 ? totalSeconds : 10.0) * 1_000_000.0
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ffmpegPath)
            
            var args = [
                "-nostdin",
                "-y",
                "-threads", "\(ProcessInfo.processInfo.activeProcessorCount)",
                "-i", sourceURL.path
            ]
            
            switch targetFormat {
            case .mp4_hevc, .mov_hevc:
                args += ["-c:v", "hevc_videotoolbox", "-b:v", "12M", "-tag:v", "hvc1", "-c:a", "aac", "-b:a", "256k"]
            case .mp4_h264, .mov_h264, .mp4_remux, .mov_remux:
                args += ["-c:v", "h264_videotoolbox", "-b:v", "14M", "-tag:v", "avc1", "-c:a", "aac", "-b:a", "256k", "-movflags", "+faststart"]
            case .gif:
                args += ["-vf", "fps=15,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"]
            case .webm:
                args += ["-c:v", "libvpx-vp9", "-b:v", "3M", "-c:a", "libopus"]
            case .mkv:
                args += ["-c:v", "h264_videotoolbox", "-b:v", "14M", "-c:a", "aac"]
            case .mp3:
                args += ["-vn", "-c:a", "libmp3lame", "-b:a", "320k"]
            case .m4a:
                args += ["-vn", "-c:a", "aac", "-b:a", "256k"]
            case .wav:
                args += ["-vn", "-c:a", "pcm_s16le"]
            default:
                args += ["-c:v", "h264_videotoolbox", "-b:v", "12M", "-c:a", "aac"]
            }
            
            // Progress pipe
            args += ["-progress", "pipe:1", destinationURL.path]
            process.arguments = args
            
            let stdoutPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = FileHandle.nullDevice
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }
            
            let handle = stdoutPipe.fileHandleForReading
            DispatchQueue.global(qos: .userInitiated).async {
                var buffer = Data()
                
                while process.isRunning || handle.availableData.count > 0 {
                    let data = handle.availableData
                    if data.isEmpty { break }
                    buffer.append(data)
                    
                    while let lineRange = buffer.range(of: Data("\n".utf8)) {
                        let lineData = buffer.subdata(in: 0..<lineRange.lowerBound)
                        buffer.removeSubrange(0..<lineRange.upperBound)
                        
                        if let line = String(data: lineData, encoding: .utf8) {
                            if line.hasPrefix("out_time_us=") {
                                let usStr = String(line.dropFirst("out_time_us=".count))
                                if let us = Double(usStr), us > 0 {
                                    let pct = min(0.99, max(0.01, us / totalMicroseconds))
                                    DispatchQueue.main.async {
                                        onProgress(pct)
                                    }
                                }
                            }
                        }
                    }
                }
                
                process.waitUntilExit()
                
                if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: destinationURL.path) {
                    let duration = CFAbsoluteTimeGetCurrent() - startTime
                    let outputSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.int64Value ?? 0
                    DispatchQueue.main.async {
                        onProgress(1.0)
                        continuation.resume(returning: (destinationURL, outputSize, duration))
                    }
                } else {
                    continuation.resume(throwing: VideoConverterError.exportSessionFailed("FFmpeg hata kodu: \(process.terminationStatus)"))
                }
            }
        }
    }
    
    // MARK: - Native AVFoundation (with Active Progress Monitoring)
    private static func convertWithAVFoundation(
        sourceURL: URL,
        destinationURL: URL,
        targetFormat: TargetFormat,
        startTime: CFAbsoluteTime,
        onProgress: @escaping (Double) -> Void
    ) async throws -> (outputURL: URL, outputSize: Int64, duration: TimeInterval) {
        let asset = AVURLAsset(url: sourceURL)
        
        let preset: String
        switch targetFormat {
        case .mp4_remux, .mov_remux:
            preset = AVAssetExportPresetPassthrough
        case .mp4_hevc, .mov_hevc:
            preset = AVAssetExportPresetHEVCHighestQuality
        default:
            preset = AVAssetExportPresetHighestQuality
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw VideoConverterError.unsupportedAsset
        }
        
        let fileType: AVFileType
        switch targetFormat {
        case .mov_h264, .mov_hevc, .mov_remux:
            fileType = .mov
        default:
            fileType = .mp4
        }
        
        // Active Progress Monitor
        let timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 80_000_000) // 80ms
                let p = Double(exportSession.progress)
                if p > 0.0 {
                    await MainActor.run {
                        onProgress(min(0.99, p))
                    }
                }
            }
        }
        
        if #available(macOS 15.0, *) {
            do {
                try await exportSession.export(to: destinationURL, as: fileType)
                timerTask.cancel()
                await MainActor.run { onProgress(1.0) }
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                let outputSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.int64Value ?? 0
                return (destinationURL, outputSize, duration)
            } catch {
                timerTask.cancel()
                throw VideoConverterError.exportSessionFailed(error.localizedDescription)
            }
        } else {
            exportSession.outputURL = destinationURL
            exportSession.outputFileType = fileType
            exportSession.shouldOptimizeForNetworkUse = true
            
            await exportSession.export()
            timerTask.cancel()
            
            switch exportSession.status {
            case .completed:
                await MainActor.run { onProgress(1.0) }
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                let outputSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.int64Value ?? 0
                return (destinationURL, outputSize, duration)
            case .failed:
                throw VideoConverterError.exportSessionFailed(exportSession.error?.localizedDescription ?? "Dışa aktarma hatası")
            case .cancelled:
                throw VideoConverterError.cancelled
            default:
                throw VideoConverterError.unknown
            }
        }
    }
}
