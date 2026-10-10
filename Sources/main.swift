import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        NotificationCenter.default.post(name: NSNotification.Name("OpenFilesRequested"), object: urls)
    }
    
    @objc func openFilesFromService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let items = pboard.pasteboardItems else { return }
        var urls: [URL] = []
        for item in items {
            if let string = item.string(forType: .fileURL), let url = URL(string: string) {
                urls.append(url)
            }
        }
        if !urls.isEmpty {
            NotificationCenter.default.post(name: NSNotification.Name("OpenFilesRequested"), object: urls)
        }
    }
}

@main
struct iConventerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
