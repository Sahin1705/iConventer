import Foundation
import SwiftUI
import AppKit

@MainActor
public class ConversionQueue: ObservableObject {
    @Published public var items: [ConversionItem] = []
    @Published public var isProcessing: Bool = false
    @Published public var overallProgress: Double = 0.0
    @Published public var processedCount: Int = 0
    
    // User Settings
    @Published public var outputFolder: URL? = nil
    @Published public var overwrite: Bool = false
    @Published public var imageQuality: Double = 0.92
    @Published public var concurrencyLimit: Int = max(2, ProcessInfo.processInfo.activeProcessorCount)
    
    public init() {}
    
    public func addFiles(urls: [URL]) {
        var collectedURLs: [URL] = []
        
        func scanURL(_ url: URL) {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    if let enumerator = FileManager.default.enumerator(
                        at: url,
                        includingPropertiesForKeys: [.isRegularFileKey],
                        options: [.skipsHiddenFiles, .skipsPackageDescendants]
                    ) {
                        for case let fileURL as URL in enumerator {
                            var isSubDir: ObjCBool = false
                            if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isSubDir), !isSubDir.boolValue {
                                collectedURLs.append(fileURL)
                            }
                        }
                    }
                } else {
                    collectedURLs.append(url)
                }
            }
        }
        
        for url in urls {
            scanURL(url)
        }
        
        let existingPaths = Set(items.map { $0.sourceURL.path })
        for url in collectedURLs {
            if !existingPaths.contains(url.path) && !url.lastPathComponent.hasPrefix(".") {
                let item = ConversionItem(url: url)
                if item.mediaType != .unknown {
                    items.append(item)
                }
            }
        }
    }
    
    public func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
        updateOverallProgress()
    }
    
    public func clearAll() {
        guard !isProcessing else { return }
        items.removeAll()
        overallProgress = 0.0
        processedCount = 0
    }
    
    public func clearCompleted() {
        guard !isProcessing else { return }
        items.removeAll { item in
            if case .completed = item.status { return true }
            return false
        }
        updateOverallProgress()
    }
    
    public func setFormatForAll(format: TargetFormat, filterType: MediaType? = nil) {
        for item in items {
            if case .completed = item.status { continue }
            if let filter = filterType {
                if item.mediaType == filter {
                    item.targetFormat = format
                }
            } else {
                item.targetFormat = format
            }
        }
    }
    
    public func updateOverallProgress() {
        guard !items.isEmpty else {
            overallProgress = 0.0
            return
        }
        let total = items.reduce(0.0) { sum, item in
            if case .completed = item.status {
                return sum + 1.0
            } else if case .converting(let p) = item.status {
                return sum + p
            } else {
                return sum
            }
        }
        overallProgress = min(1.0, max(0.0, total / Double(items.count)))
    }
    
    public func startBatch() {
        guard !isProcessing else { return }
        let pendingItems = items.filter { item in
            if case .completed = item.status { return false }
            return true
        }
        guard !pendingItems.isEmpty else { return }
        
        isProcessing = true
        processedCount = 0
        overallProgress = 0.0
        
        let limit = concurrencyLimit
        let outFolder = outputFolder
        let ovr = overwrite
        let qual = imageQuality
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                var activeTasks = 0
                var queueIndex = 0
                
                while queueIndex < pendingItems.count || activeTasks > 0 {
                    while activeTasks < limit && queueIndex < pendingItems.count {
                        let item = pendingItems[queueIndex]
                        queueIndex += 1
                        activeTasks += 1
                        
                        group.addTask {
                            await self.convertItem(
                                item: item,
                                outputFolder: outFolder,
                                quality: qual,
                                overwrite: ovr
                            )
                        }
                    }
                    
                    if activeTasks > 0 {
                        await group.next()
                        activeTasks -= 1
                        self.processedCount += 1
                        self.updateOverallProgress()
                    }
                }
            }
            
            self.overallProgress = 1.0
            self.isProcessing = false
            NSSound(named: "Glass")?.play()
        }
    }
    
    private func convertItem(
        item: ConversionItem,
        outputFolder: URL?,
        quality: Double,
        overwrite: Bool
    ) async {
        await MainActor.run {
            item.status = .converting(progress: 0.01)
            item.progress = 0.01
            self.updateOverallProgress()
        }
        
        do {
            switch item.targetFormat.mediaType {
            case .image:
                let result = try ImageConverter.convert(
                    sourceURL: item.sourceURL,
                    targetFormat: item.targetFormat,
                    outputFolder: outputFolder,
                    quality: quality,
                    overwrite: overwrite
                )
                await MainActor.run {
                    item.progress = 1.0
                    item.status = .completed(
                        outputURL: result.outputURL,
                        outputSize: result.outputSize,
                        duration: result.duration
                    )
                    self.updateOverallProgress()
                }
                
            case .video:
                let result = try await VideoConverter.convert(
                    sourceURL: item.sourceURL,
                    targetFormat: item.targetFormat,
                    outputFolder: outputFolder,
                    overwrite: overwrite
                ) { p in
                    Task { @MainActor in
                        item.progress = p
                        item.status = .converting(progress: p)
                        self.updateOverallProgress()
                    }
                }
                await MainActor.run {
                    item.progress = 1.0
                    item.status = .completed(
                        outputURL: result.outputURL,
                        outputSize: result.outputSize,
                        duration: result.duration
                    )
                    self.updateOverallProgress()
                }
                
            case .audio:
                let result = try await AudioConverter.convert(
                    sourceURL: item.sourceURL,
                    targetFormat: item.targetFormat,
                    outputFolder: outputFolder,
                    overwrite: overwrite
                ) { p in
                    Task { @MainActor in
                        item.progress = p
                        item.status = .converting(progress: p)
                        self.updateOverallProgress()
                    }
                }
                await MainActor.run {
                    item.progress = 1.0
                    item.status = .completed(
                        outputURL: result.outputURL,
                        outputSize: result.outputSize,
                        duration: result.duration
                    )
                    self.updateOverallProgress()
                }
                
            case .unknown:
                throw ImageConverterError.conversionFailed("Desteklenmeyen format")
            }
        } catch {
            await MainActor.run {
                item.status = .failed(error: error.localizedDescription)
                self.updateOverallProgress()
            }
        }
    }
}
