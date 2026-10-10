import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum ImageConverterError: LocalizedError {
    case invalidSource
    case failedToCreateDestination
    case conversionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidSource:
            return "Kaynak görsel okunamadı."
        case .failedToCreateDestination:
            return "Hedef dosya oluşturulamadı."
        case .conversionFailed(let msg):
            return "Dönüştürme hatası: \(msg)"
        }
    }
}

public struct ImageConverter {
    public static func convert(
        sourceURL: URL,
        targetFormat: TargetFormat,
        outputFolder: URL? = nil,
        quality: Double = 0.92,
        overwrite: Bool = false
    ) throws -> (outputURL: URL, outputSize: Int64, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let targetExt = targetFormat.fileExtension
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let targetDirectory = outputFolder ?? sourceURL.deletingLastPathComponent()
        
        var destinationURL = targetDirectory.appendingPathComponent("\(baseName).\(targetExt)")
        
        // If file exists and overwrite is false, find unique name
        if !overwrite && FileManager.default.fileExists(atPath: destinationURL.path) {
            var counter = 1
            while FileManager.default.fileExists(atPath: destinationURL.path) {
                destinationURL = targetDirectory.appendingPathComponent("\(baseName)_\(counter).\(targetExt)")
                counter += 1
            }
        }
        
        // Match target UTI
        let utiString: CFString
        switch targetFormat {
        case .jpeg:
            utiString = UTType.jpeg.identifier as CFString
        case .png:
            utiString = UTType.png.identifier as CFString
        case .heic:
            utiString = "public.heic" as CFString
        case .webp:
            utiString = "org.webmproject.webp" as CFString
        case .tiff:
            utiString = UTType.tiff.identifier as CFString
        default:
            utiString = UTType.jpeg.identifier as CFString
        }
        
        // Method 1: Apple Silicon Native ImageIO with Hardware Decoder
        let sourceOptions = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceShouldAllowFloat: true
        ] as CFDictionary
        
        if let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, sourceOptions),
           let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, utiString, 1, nil) {
            
            var destinationOptions: [CFString: Any] = [:]
            if targetFormat == .jpeg || targetFormat == .heic {
                destinationOptions[kCGImageDestinationLossyCompressionQuality] = quality
            }
            
            // Retain image metadata and color profile
            CGImageDestinationAddImageFromSource(destination, imageSource, 0, destinationOptions as CFDictionary)
            
            if CGImageDestinationFinalize(destination) {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                let outputSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.int64Value ?? 0
                return (destinationURL, outputSize, duration)
            }
        }
        
        // Method 2: Fallback to macOS native sips
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        
        var sipsFormat = "jpeg"
        switch targetFormat {
        case .jpeg: sipsFormat = "jpeg"
        case .png: sipsFormat = "png"
        case .heic: sipsFormat = "heic"
        case .tiff: sipsFormat = "tiff"
        default: sipsFormat = "jpeg"
        }
        
        process.arguments = ["-s", "format", sipsFormat, sourceURL.path, "--out", destinationURL.path]
        let pipe = Pipe()
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: destinationURL.path) {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                let outputSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? NSNumber)?.int64Value ?? 0
                return (destinationURL, outputSize, duration)
            } else {
                let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorStr = String(data: errorData, encoding: .utf8) ?? "Bilinmeyen sips hatası"
                throw ImageConverterError.conversionFailed(errorStr)
            }
        } catch {
            throw ImageConverterError.conversionFailed(error.localizedDescription)
        }
    }
}
