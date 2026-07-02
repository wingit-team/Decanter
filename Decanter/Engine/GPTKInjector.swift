//
//  GPTKInjector.swift
//  Decanter
//

import Foundation

public class GPTKInjector {
    public static let shared = GPTKInjector()
    
    private let fm = FileManager.default
    
    /// Dylibs to symlink for GPTK 1.x / 2.x layouts into system32.
    private let system32Dylibs: [(src: String, dst: String)] = [
        ("d3dmetal.dylib", "d3dmetal.dll"),
        ("libMoltenVK.dylib", "libMoltenVK.dylib"),
        ("libD3DShared.dylib", "libD3DShared.dylib")
    ]
    
    /// Registry overrides required for D3DMetal to intercept Direct3D calls.
    private let dllOverrides: [(dll: String, overrideType: String)] = [
        ("d3d11", "native,builtin"),
        ("d3d12", "native,builtin"),
        ("d3d9", "native,builtin"),
        ("dxgi", "native,builtin"),
        ("d3dmetal", "native,builtin")
    ]
    
    /// Injects GPTK files and sets registry overrides in the bottle's prefix.
    public func injectGPTK(bottle: Bottle, gptk: GPTKPaths, winePath: String) async throws -> Bottle {
        let system32Path = (bottle.path as NSString).appendingPathComponent("drive_c/windows/system32")
        
        try fm.createDirectory(atPath: system32Path, withIntermediateDirectories: true, attributes: nil)
        
        let home = fm.homeDirectoryForCurrentUser.path
        let targetFramework = (home as NSString).appendingPathComponent("Library/Frameworks/D3DMetal.framework")
        
        // Step 1: Framework and Dylib Setup
        if let fwPath = gptk.frameworkPath, fm.fileExists(atPath: fwPath) {
            if !fm.fileExists(atPath: targetFramework) {
                let localFrameworks = (home as NSString).appendingPathComponent("Library/Frameworks")
                try? fm.createDirectory(atPath: localFrameworks, withIntermediateDirectories: true)
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/cp")
                process.arguments = ["-R", fwPath, targetFramework]
                try process.run()
                process.waitUntilExit()
            }
        }
        
        let gptkLib = gptk.libDir
        let wineWindows = (gptkLib as NSString).appendingPathComponent("wine/x86_64-windows")
        let wineUnix = (gptkLib as NSString).appendingPathComponent("wine/x86_64-unix")
        
        var isWindowsDir: ObjCBool = false
        if fm.fileExists(atPath: wineWindows, isDirectory: &isWindowsDir), isWindowsDir.boolValue {
            // GPTK 3.x layout - copy DLLs & SO files directly
            if let dllEntries = try? fm.contentsOfDirectory(atPath: wineWindows) {
                for file in dllEntries where file.hasSuffix(".dll") {
                    let src = (wineWindows as NSString).appendingPathComponent(file)
                    let dst = (system32Path as NSString).appendingPathComponent(file)
                    try? fm.removeItem(atPath: dst)
                    try? fm.copyItem(atPath: src, toPath: dst)
                }
            }
            if let soEntries = try? fm.contentsOfDirectory(atPath: wineUnix) {
                for file in soEntries where file.hasSuffix(".so") {
                    let src = (wineUnix as NSString).appendingPathComponent(file)
                    let dst = (system32Path as NSString).appendingPathComponent(file)
                    try? fm.removeItem(atPath: dst)
                    try? fm.copyItem(atPath: src, toPath: dst)
                }
            }
        } else {
            // GPTK 1.x / 2.x layout - symlink dylibs into system32
            for pair in system32Dylibs {
                let src = (gptkLib as NSString).appendingPathComponent(pair.src)
                let dst = (system32Path as NSString).appendingPathComponent(pair.dst)
                
                if fm.fileExists(atPath: src) {
                    try? fm.removeItem(atPath: dst)
                    try? fm.createSymbolicLink(atPath: dst, withDestinationPath: src)
                }
            }
        }
        
        // Copy libd3dshared if available
        if let shared = gptk.d3dShared, fm.fileExists(atPath: shared) {
            for dstName in ["libd3dshared.dylib", "libD3DShared.dylib"] {
                let dst = (system32Path as NSString).appendingPathComponent(dstName)
                try? fm.removeItem(atPath: dst)
                try? fm.copyItem(atPath: shared, toPath: dst)
                
                let localFw = (home as NSString).appendingPathComponent("Library/Frameworks/\(dstName)")
                try? fm.removeItem(atPath: localFw)
                try? fm.copyItem(atPath: shared, toPath: localFw)
            }
        }
        
        // Step 2: Set Wine Registry DLL Overrides
        let envManager = WineEnvironmentManager()
        let env = envManager.buildEnvironment(bottle: bottle, gptk: gptk)
        
        for override in dllOverrides {
            let regKey = #"HKCU\Software\Wine\DllOverrides"#
            let process = Process()
            process.executableURL = URL(fileURLWithPath: winePath)
            process.arguments = ["reg", "add", regKey, "/v", override.dll, "/d", override.overrideType, "/f"]
            process.environment = env
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Warning: Failed to set registry override for \(override.dll): \(error)")
            }
        }
        
        var updatedBottle = bottle
        updatedBottle.gptkInjected = true
        return updatedBottle
    }
}
