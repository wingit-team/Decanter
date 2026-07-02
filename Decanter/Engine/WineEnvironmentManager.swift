//
//  WineEnvironmentManager.swift
//  Decanter
//

import Foundation

public class WineEnvironmentManager {
    public init() {}
    
    /// Constructs environment variables for running commands within a Wine prefix.
    public func buildEnvironment(bottle: Bottle, gptk: GPTKPaths? = nil, extraEnv: [String: String] = [:]) -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        
        // Basic Wine Prefix Settings
        env["WINEPREFIX"] = bottle.path
        env["WINEARCH"] = bottle.arch
        
        // Synchronization Protocol Flags
        if bottle.useEsync {
            env["WINEESYNC"] = "1"
        } else {
            env.removeValue(forKey: "WINEESYNC")
        }
        
        if bottle.useMsync {
            env["WINEMSYNC"] = "1"
        } else {
            env.removeValue(forKey: "WINEMSYNC")
        }
        
        // Metal HUD Overlay
        env["MTL_HUD_ENABLED"] = bottle.showMetalHUD ? "1" : "0"
        env["WINE_SIMULATE_VIRTUAL_DESKTOP"] = "off"
        
        // Linker & Library Paths
        var fallbackLibs: [String] = []
        var fallbackFrameworks: [String] = []
        
        // Bottle system32 path
        let system32 = (bottle.path as NSString).appendingPathComponent("drive_c/windows/system32")
        fallbackLibs.append(system32)
        
        // Local Frameworks
        let userFrameworks = (home as NSString).appendingPathComponent("Library/Frameworks")
        fallbackFrameworks.append(userFrameworks)
        fallbackLibs.append(userFrameworks)
        
        // D3DMetal Framework Resources
        let d3dResources = (userFrameworks as NSString).appendingPathComponent("D3DMetal.framework/Versions/A/Resources")
        if FileManager.default.fileExists(atPath: d3dResources) {
            fallbackLibs.append(d3dResources)
        }
        
        // GPTK library paths if available
        if let gptk = gptk {
            if !gptk.libDir.isEmpty {
                fallbackLibs.append(gptk.libDir)
            }
            // MoltenVK optimization flags
            env["MVK_CONFIG_FULL_IMAGE_VIEW_SWIZZLE"] = "1"
            env["MVK_CONFIG_RESUME_LOST_INSTANCE"] = "1"
            env["MVK_ALLOW_METAL_FENCES"] = "1"
        }
        
        // Standard system libraries fallback
        fallbackLibs.append("/usr/local/lib")
        fallbackLibs.append("/usr/lib")
        
        // Combine fallback paths
        let existingFallback = env["DYLD_FALLBACK_LIBRARY_PATH"] ?? ""
        if existingFallback.isEmpty {
            env["DYLD_FALLBACK_LIBRARY_PATH"] = fallbackLibs.joined(separator: ":")
        } else {
            env["DYLD_FALLBACK_LIBRARY_PATH"] = (fallbackLibs + [existingFallback]).joined(separator: ":")
        }
        
        let existingFwFallback = env["DYLD_FALLBACK_FRAMEWORK_PATH"] ?? ""
        if existingFwFallback.isEmpty {
            env["DYLD_FALLBACK_FRAMEWORK_PATH"] = fallbackFrameworks.joined(separator: ":")
        } else {
            env["DYLD_FALLBACK_FRAMEWORK_PATH"] = (fallbackFrameworks + [existingFwFallback]).joined(separator: ":")
        }
        
        // Merge extra custom overrides
        for (key, value) in extraEnv {
            env[key] = value
        }
        
        return env
    }
}
