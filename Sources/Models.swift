import Foundation
import SwiftUI

public enum MediaType: String, CaseIterable, Identifiable {
    case video = "Video"
    case image = "Görsel"
    case audio = "Ses"
    case unknown = "Diğer"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .video: return "video.fill"
        case .image: return "photo.fill"
        case .audio: return "music.note"
        case .unknown: return "doc.fill"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .video: return .purple
        case .image: return .orange
        case .audio: return .blue
        case .unknown: return .gray
        }
    }
}

public enum TargetFormat: String, CaseIterable, Identifiable {
    // Images
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"
    case webp = "WebP"
    case tiff = "TIFF"
    
    // Videos
    case mp4_remux = "MP4 (Yıldırım Hızı Remux • 0.2s)"
    case mp4_h264 = "MP4 (H.264 M5 Donanım)"
    case mp4_hevc = "MP4 (HEVC / H.265 M5)"
    case mov_remux = "MOV (Yıldırım Hızı Remux)"
    case mov_h264 = "MOV (H.264 M5 Donanım)"
    case mov_hevc = "MOV (HEVC / ProRes)"
    case mkv = "MKV"
    case webm = "WebM"
    case gif = "Animasyonlu GIF"
    
    // Audio
    case mp3 = "MP3"
    case m4a = "M4A (AAC)"
    case wav = "WAV"
    
    public var id: String { rawValue }
    
    public var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .heic: return "heic"
        case .webp: return "webp"
        case .tiff: return "tiff"
        case .mp4_remux, .mp4_h264, .mp4_hevc: return "mp4"
        case .mov_remux, .mov_h264, .mov_hevc: return "mov"
        case .mkv: return "mkv"
        case .webm: return "webm"
        case .gif: return "gif"
        case .mp3: return "mp3"
        case .m4a: return "m4a"
        case .wav: return "wav"
        }
    }
    
    public var mediaType: MediaType {
        switch self {
        case .jpeg, .png, .heic, .webp, .tiff:
            return .image
        case .mp4_remux, .mp4_h264, .mp4_hevc, .mov_remux, .mov_h264, .mov_hevc, .mkv, .webm, .gif:
            return .video
        case .mp3, .m4a, .wav:
            return .audio
        }
    }
    
    public var isHardwareAccelerated: Bool {
        switch self {
        case .mp4_remux, .mov_remux:
            return true // Zero-copy passthrough
        case .mp4_h264, .mp4_hevc, .mov_h264, .mov_hevc, .heic, .jpeg, .png:
            return true
        default:
            return false
        }
    }
    
    public var badgeText: String {
        switch self {
        case .mp4_remux, .mov_remux:
            return "⚡️ Anında Remux (Kayıpsız)"
        case .mp4_h264, .mp4_hevc, .mov_h264, .mov_hevc:
            return "⚡️ M5 Donanım Hızlandırıcı"
        default:
            return ""
        }
    }
}

public enum ItemStatus: Equatable {
    case pending
    case converting(progress: Double)
    case completed(outputURL: URL, outputSize: Int64, duration: TimeInterval)
    case failed(error: String)
    
    public var title: String {
        switch self {
        case .pending:
            return "Bekliyor"
        case .converting(let p):
            return String(format: "Çevriliyor %%%.0f", p * 100)
        case .completed:
            return "Tamamlandı"
        case .failed(let err):
            return "Hata: \(err)"
        }
    }
}

public class ConversionItem: Identifiable, ObservableObject {
    public let id = UUID()
    public let sourceURL: URL
    public let fileName: String
    public let sourceExtension: String
    public let originalSize: Int64
    public let mediaType: MediaType
    
    @Published public var targetFormat: TargetFormat
    @Published public var status: ItemStatus = .pending
    @Published public var progress: Double = 0.0
    
    public init(url: URL) {
        self.sourceURL = url
        self.fileName = url.lastPathComponent
        self.sourceExtension = url.pathExtension.lowercased()
        
        let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
        self.originalSize = (attr?[.size] as? NSNumber)?.int64Value ?? 0
        
        // Determine media type
        let ext = sourceExtension
        if ["mov", "mp4", "m4v", "mkv", "webm", "avi", "flv", "wmv", "3gp"].contains(ext) {
            self.mediaType = .video
        } else if ["heic", "heif", "jpg", "jpeg", "png", "webp", "tiff", "tif", "bmp", "gif", "avif"].contains(ext) {
            self.mediaType = .image
        } else if ["mp3", "m4a", "wav", "aac", "flac", "ogg", "aiff"].contains(ext) {
            self.mediaType = .audio
        } else {
            self.mediaType = .unknown
        }
        
        // Smart target selection
        switch ext {
        case "mov":
            self.targetFormat = .mp4_remux // Lightning fast remux
        case "mp4":
            self.targetFormat = .mov_remux
        case "mkv", "webm", "avi", "flv", "m4v":
            self.targetFormat = .mp4_remux
        case "heic", "heif":
            self.targetFormat = .jpeg
        case "jpg", "jpeg":
            self.targetFormat = .png
        case "png":
            self.targetFormat = .jpeg
        case "webp":
            self.targetFormat = .jpeg
        case "wav", "flac", "aiff":
            self.targetFormat = .mp3
        case "mp3":
            self.targetFormat = .m4a
        default:
            if self.mediaType == .video {
                self.targetFormat = .mp4_remux
            } else if self.mediaType == .image {
                self.targetFormat = .jpeg
            } else if self.mediaType == .audio {
                self.targetFormat = .mp3
            } else {
                self.targetFormat = .jpeg
            }
        }
    }
    
    public var formattedOriginalSize: String {
        ByteCountFormatter.string(fromByteCount: originalSize, countStyle: .file)
    }
}
