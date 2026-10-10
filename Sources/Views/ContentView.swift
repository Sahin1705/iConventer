import SwiftUI
import AppKit

public struct ContentView: View {
    @StateObject private var queue = ConversionQueue()
    @State private var showingSettings: Bool = false
    @State private var isWindowDropTargeted: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top App Bar
            headerView
            
            Divider()
            
            // Main Content Area
            if queue.items.isEmpty {
                DropZoneView(queue: queue)
                    .padding(24)
            } else {
                fileListView
            }
            
            Divider()
            
            // Bottom Action Bar
            bottomBarView
        }
        .frame(minWidth: 880, minHeight: 580)
        .sheet(isPresented: $showingSettings) {
            SettingsSheetView(queue: queue)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenFilesRequested"))) { notification in
            if let urls = notification.object as? [URL] {
                queue.addFiles(urls: urls)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 14) {
            // App Branding
            HStack(spacing: 10) {
                ZStack {
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 34, height: 34)
                    .cornerRadius(8)
                    
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("iConverter")
                        .font(.system(size: 16, weight: .bold))
                    Text("Apple Silicon Ultra-Hızlı Medya Çevirici")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Quick preset buttons if there are items
            if !queue.items.isEmpty {
                HStack(spacing: 8) {
                    Button(action: {
                        queue.setFormatForAll(format: .jpeg, filterType: .image)
                    }) {
                        Label("Tüm HEIC → JPEG", systemImage: "photo")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .disabled(queue.isProcessing)
                    
                    Button(action: {
                        queue.setFormatForAll(format: .mp4_remux, filterType: .video)
                    }) {
                        Label("Tüm MOV → MP4", systemImage: "film")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .disabled(queue.isProcessing)
                }
            }
            
            // Hardware Badge
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("\(HardwareInfo.shared.chipName)")
                    .font(.system(size: 11, weight: .semibold))
                Text("• \(HardwareInfo.shared.coreCount) Çekirdek")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            // Settings Button
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
            }
            .buttonStyle(.borderless)
            .help("Ayarlar & Donanım Bilgisi")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - File List
    private var fileListView: some View {
        VStack(spacing: 0) {
            // Drag more banner
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                Text("Daha fazla dosya veya klasör sürükleyin")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: openFileDialog) {
                    Label("Dosya Ekle", systemImage: "doc.badge.plus")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if !queue.isProcessing {
                    Button(action: { queue.clearAll() }) {
                        Label("Temizle", systemImage: "trash")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(isWindowDropTargeted ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.06))
            .onDrop(of: [.fileURL], isTargeted: $isWindowDropTargeted) { providers in
                loadDroppedFiles(from: providers)
                return true
            }
            
            Divider()
            
            // List of items
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(queue.items) { item in
                        ItemRowView(item: item) {
                            queue.removeItem(id: item.id)
                        }
                    }
                }
                .padding(18)
            }
        }
    }
    
    // MARK: - Bottom Bar
    private var bottomBarView: some View {
        HStack(spacing: 16) {
            // Status Summary
            VStack(alignment: .leading, spacing: 2) {
                let total = queue.items.count
                let completed = queue.items.filter { if case .completed = $0.status { return true }; return false }.count
                let pending = total - completed
                
                Text("Toplam: \(total) dosya (\(completed) tamamlandı, \(pending) bekliyor)")
                    .font(.system(size: 12, weight: .semibold))
                
                if let folder = queue.outputFolder {
                    Text("Kayıt: \(folder.path)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Kayıt: Orijinal dosyanın yanı")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if queue.isProcessing {
                HStack(spacing: 12) {
                    ProgressView(value: queue.overallProgress, total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(width: 140)
                    
                    Text(String(format: "%%% .0f", queue.overallProgress * 100))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
            }
            
            // Start Conversion Button
            Button(action: {
                queue.startBatch()
            }) {
                HStack(spacing: 8) {
                    if queue.isProcessing {
                        ProgressView()
                            .controlSize(.small)
                        Text("Dönüştürülüyor...")
                    } else {
                        Image(systemName: "bolt.fill")
                        Text("Tümünü Çevir")
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(queue.isProcessing || queue.items.isEmpty || queue.items.allSatisfy { if case .completed = $0.status { return true }; return false })
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func openFileDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.item]
        panel.begin { response in
            if response == .OK {
                queue.addFiles(urls: panel.urls)
            }
        }
    }
    
    private func loadDroppedFiles(from providers: [NSItemProvider]) {
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
