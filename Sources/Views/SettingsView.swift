import SwiftUI
import AppKit

public struct SettingsSheetView: View {
    @ObservedObject var queue: ConversionQueue
    @Environment(\.presentationMode) var presentationMode
    
    public init(queue: ConversionQueue) {
        self.queue = queue
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Label("Ayarlar & Donanım", systemImage: "gearshape.fill")
                    .font(.title3.bold())
                Spacer()
                Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.bottom, 4)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Apple Silicon Status Box
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.green)
                            Text("Apple Silicon Donanım Durumu")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• İşlemci: \(HardwareInfo.shared.chipName)")
                            Text("• CPU Çekirdekleri: \(HardwareInfo.shared.coreCount) Aktif Çekirdek")
                            Text("• Bellek: \(HardwareInfo.shared.memoryFormatted)")
                            Text("• VideoToolbox H.264: \(HardwareInfo.shared.hasVideoToolboxH264 ? "Aktif (Donanım Destekli)" : "Yok")")
                            Text("• VideoToolbox HEVC: \(HardwareInfo.shared.hasVideoToolboxHEVC ? "Aktif (Donanım Destekli)" : "Yok")")
                            Text("• VideoToolbox ProRes: \(HardwareInfo.shared.hasVideoToolboxProRes ? "Aktif (Donanım Destekli)" : "Yok")")
                            Text("• ImageIO HEIF Donanım Dekoderi: Aktif")
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.08)))
                    
                    // Output Folder Setting
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kayıt Konumu")
                            .font(.headline)
                        
                        HStack {
                            Text(queue.outputFolder?.path ?? "Orijinal Dosyanın Yanına Kaydet")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            if queue.outputFolder != nil {
                                Button("Sıfırla") {
                                    queue.outputFolder = nil
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Button("Klasör Seç...") {
                                selectFolder()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    // Concurrency limit
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Eşzamanlı İşlem Sayısı (Paralel Çekirdekler):")
                                .font(.headline)
                            Spacer()
                            Text("\(queue.concurrencyLimit) Görev")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(queue.concurrencyLimit) },
                            set: { queue.concurrencyLimit = Int($0) }
                        ), in: 1...16, step: 1)
                        
                        Text("Apple M5 için önerilen: 10 çekirdek (Tüm P ve E çekirdekleri tam kapasite çalışır)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Image Quality Setting
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Görsel Sıkıştırma Kalitesi:")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%%% .0f", queue.imageQuality * 100))
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        }
                        
                        Slider(value: $queue.imageQuality, in: 0.5...1.0, step: 0.05)
                        
                        Text("JPEG ve HEIC için kalite faktörü (Önerilen: %92)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Overwrite toggle
                    Toggle("Mevcut dosyaların üzerine yaz", isOn: $queue.overwrite)
                        .font(.body)
                }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Tamam") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 520, height: 540)
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == .OK, let url = panel.url {
                queue.outputFolder = url
            }
        }
    }
}
