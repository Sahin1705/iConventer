import Foundation
import VideoToolbox
import AVFoundation

public struct HardwareInfo {
    public static let shared = HardwareInfo()
    
    public let chipName: String
    public let coreCount: Int
    public let memoryFormatted: String
    public let hasVideoToolboxHEVC: Bool
    public let hasVideoToolboxH264: Bool
    public let hasVideoToolboxProRes: Bool
    
    private init() {
        // CPU Name
        var size: size_t = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var brand = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0)
        let brandStr = String(cString: brand).trimmingCharacters(in: .whitespacesAndNewlines)
        self.chipName = brandStr.isEmpty ? "Apple Silicon (M-Series)" : brandStr
        
        // Cores
        self.coreCount = ProcessInfo.processInfo.activeProcessorCount
        
        // RAM
        let memBytes = ProcessInfo.processInfo.physicalMemory
        let memGB = Double(memBytes) / (1024.0 * 1024.0 * 1024.0)
        self.memoryFormatted = String(format: "%.0f GB", memGB)
        
        // VideoToolbox Encoders
        var hasHEVC = false
        var hasH264 = false
        var hasProRes = false
        
        var encoderList: CFArray?
        if VTCopyVideoEncoderList(nil, &encoderList) == noErr, let encoders = encoderList as? [[String: Any]] {
            for encoder in encoders {
                if let codecType = encoder[kVTVideoEncoderList_CodecType as String] as? NSNumber {
                    let fourCC = codecType.uint32Value
                    if fourCC == kCMVideoCodecType_HEVC {
                        hasHEVC = true
                    } else if fourCC == kCMVideoCodecType_H264 {
                        hasH264 = true
                    } else if fourCC == kCMVideoCodecType_AppleProRes422 || fourCC == kCMVideoCodecType_AppleProRes4444 {
                        hasProRes = true
                    }
                }
            }
        }
        
        self.hasVideoToolboxHEVC = hasHEVC
        self.hasVideoToolboxH264 = hasH264
        self.hasVideoToolboxProRes = hasProRes
    }
}
