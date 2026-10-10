import SwiftUI
import AppKit

public struct ItemRowView: View {
    @ObservedObject var item: ConversionItem
    let onRemove: () -> Void
    
    public init(item: ConversionItem, onRemove: @escaping () -> Void) {
        self.item = item
        self.onRemove = onRemove
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Media Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.mediaType.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.mediaType.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(item.mediaType.accentColor)
            }
            
            // Name and Details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.fileName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack(spacing: 8) {
                    Text(item.sourceExtension.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                    
                    Text(item.formattedOriginalSize)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if !item.targetFormat.badgeText.isEmpty {
                        Text(item.targetFormat.badgeText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // Target Format Picker
            Menu {
                ForEach(availableFormats(for: item.mediaType)) { format in
                    Button(action: { item.targetFormat = format }) {
                        HStack {
                            Text(format.rawValue)
                            if format == item.targetFormat {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.secondary)
                    Text(item.targetFormat.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(isRowDisabled)
            
            // Status & Action Area
            statusView
                .frame(minWidth: 170, alignment: .trailing)
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary.opacity(0.6))
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .disabled(isRowDisabled)
            .help("Listeden Kaldır")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
    
    private var isRowDisabled: Bool {
        if case .converting = item.status {
            return true
        }
        return false
    }
    
    @ViewBuilder
    private var statusView: some View {
        switch item.status {
        case .pending:
            Text("Bekliyor")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(6)
            
        case .converting(let progress):
            VStack(alignment: .trailing, spacing: 3) {
                ProgressView(value: max(0.02, progress), total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 130)
                
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.mini)
                    Text(String(format: "%%% .0f", max(1.0, progress * 100)))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                }
            }
            
        case .completed(let outputURL, let outputSize, let duration):
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 11))
                        Text(String(format: "%.2fs", duration))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    
                    Text(ByteCountFormatter.string(fromByteCount: outputSize, countStyle: .file))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                }) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .help("Finder'da Göster")
            }
            
        case .failed(let error):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Hata")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.red)
            }
            .help(error)
        }
    }
    
    private func availableFormats(for type: MediaType) -> [TargetFormat] {
        switch type {
        case .video:
            return [.mp4_remux, .mp4_h264, .mp4_hevc, .mov_remux, .mov_h264, .mov_hevc, .mkv, .webm, .gif, .mp3, .m4a, .wav]
        case .image:
            return [.jpeg, .png, .heic, .webp, .tiff]
        case .audio:
            return [.mp3, .m4a, .wav]
        case .unknown:
            return [.jpeg, .mp4_remux]
        }
    }
}
