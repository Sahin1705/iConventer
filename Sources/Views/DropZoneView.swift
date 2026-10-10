import SwiftUI
import UniformTypeIdentifiers
import AppKit

public struct DropZoneView: View {
    @ObservedObject var queue: ConversionQueue
    @State private var isTargeted: Bool = false
    
    public init(queue: ConversionQueue) {
        self.queue = queue
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: isTargeted ? 3 : 2, dash: [8, 6])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor).opacity(0.5))
                )
            
            VStack(spacing: 20) {
                // M5 Chip Badge
                HStack(spacing: 6) {
                    Image(systemName: "cpu.fill")
                        .foregroundColor(.green)
                    Text("\(HardwareInfo.shared.chipName) (\(HardwareInfo.shared.coreCount) Çekirdek) Donanım Hızlandırma Aktif")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(NSColor.windowBackgroundColor)))
                .overlay(Capsule().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 84, height: 84)
                    
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 52, height: 52)
                        .foregroundColor(.accentColor)
                }
                
                VStack(spacing: 6) {
                    Text("Dosyaları veya Klasörleri Buraya Sürükleyin")
                        .font(.title2.bold())
                    
                    Text("MOV to MP4, HEIC to JPEG, WebP, PNG ve tüm formatlar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Button(action: openFileDialog) {
                        Label("Dosya Seç", systemImage: "doc.badge.plus")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: openFolderDialog) {
                        Label("Klasör Seç", systemImage: "folder.badge.plus")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
                
                // Format tags
                HStack(spacing: 8) {
                    formatTag("MOV → MP4")
                    formatTag("HEIC → JPEG")
                    formatTag("PNG ↔ JPEG")
                    formatTag("MKV → MP4")
                    formatTag("Ses / Video")
                }
                .padding(.top, 6)
            }
            .padding(32)
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            loadFiles(from: providers)
            return true
        }
    }
    
    private func formatTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.12))
            .cornerRadius(6)
            .foregroundColor(.secondary)
    }
    
    private func openFileDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.item]
        panel.begin { response in
            if response == .OK {
                queue.addFiles(urls: panel.urls)
            }
        }
    }
    
    private func openFolderDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.begin { response in
            if response == .OK {
                queue.addFiles(urls: panel.urls)
            }
        }
    }
    
    private func loadFiles(from providers: [NSItemProvider]) {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    urls.append(url)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            queue.addFiles(urls: urls)
        }
    }
}
