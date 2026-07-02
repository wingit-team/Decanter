//
//  GPTKDetector.swift
//  Decanter
//

import Foundation

public struct GPTKPaths: Codable, Equatable {
    public var volumeRoot: String
    public var libDir: String
    public var d3dmetal: String
    public var moltenvk: String
    public var d3dShared: String?
    public var frameworkPath: String?
    public var version: String
    
    public init(
        volumeRoot: String,
        libDir: String,
        d3dmetal: String,
        moltenvk: String,
        d3dShared: String? = nil,
        frameworkPath: String? = nil,
        version: String = "Unknown"
    ) {
        self.volumeRoot = volumeRoot
        self.libDir = libDir
        self.d3dmetal = d3dmetal
        self.moltenvk = moltenvk
        self.d3dShared = d3dShared
        self.frameworkPath = frameworkPath
        self.version = version
    }
}

public class GPTKDetector {
    public static let shared = GPTKDetector()
    
    private let fm = FileManager.default
    
    /// Scans the system for Apple Game Porting Toolkit (GPTK) installations or mounted volumes.
    public func detectGPTK() -> GPTKPaths? {
        // 1. Check mounted /Volumes for GPTK DMG
        let volumesPath = "/Volumes"
        if let entries = try? fm.contentsOfDirectory(atPath: volumesPath) {
            for volName in entries {
                if isGPTKVolume(volName) {
                    let volRoot = (volumesPath as NSString).appendingPathComponent(volName)
                    if let paths = resolveDylibsFromVolume(volRoot: volRoot, volName: volName) {
                        return paths
                    }
                }
            }
        }
        
        // 2. Check local ~/Library/Frameworks/D3DMetal.framework
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let frameworkPath = (home as NSString).appendingPathComponent("Library/Frameworks/D3DMetal.framework")
        let d3dSharedPath = (home as NSString).appendingPathComponent("Library/Frameworks/libd3dshared.dylib")
        
        if fm.fileExists(atPath: frameworkPath) {
            let libDir = (home as NSString).appendingPathComponent("Library/Frameworks")
            return GPTKPaths(
                volumeRoot: frameworkPath,
                libDir: libDir,
                d3dmetal: (frameworkPath as NSString).appendingPathComponent("D3DMetal"),
                moltenvk: "",
                d3dShared: fm.fileExists(atPath: d3dSharedPath) ? d3dSharedPath : nil,
                frameworkPath: frameworkPath,
                version: "Installed D3DMetal"
            )
        }
        
        return nil
    }
    
    private func isGPTKVolume(_ name: String) -> Bool {
        let lower = name.lowercased()
        return lower.contains("game_porting_toolkit")
            || lower.contains("game porting toolkit")
            || lower.contains("gptk")
            || lower.contains("evaluation environment")
    }
    
    private func resolveDylibsFromVolume(volRoot: String, volName: String) -> GPTKPaths? {
        let searchSubdirs = ["lib", "redist/lib", "Wine/lib", "."]
        
        for subdir in searchSubdirs {
            let libDir = (volRoot as NSString).appendingPathComponent(subdir)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: libDir, isDirectory: &isDir), isDir.boolValue else {
                continue
            }
            
            let d3dmetalPath = (libDir as NSString).appendingPathComponent("d3dmetal.dylib")
            let moltenvkPath = (libDir as NSString).appendingPathComponent("libMoltenVK.dylib")
            let d3dShared1 = (libDir as NSString).appendingPathComponent("libD3DShared.dylib")
            let d3dShared2 = (libDir as NSString).appendingPathComponent("external/libd3dshared.dylib")
            let wineDlls = (libDir as NSString).appendingPathComponent("wine/x86_64-windows/d3d11.dll")
            
            let hasD3DMetal = fm.fileExists(atPath: d3dmetalPath)
            let hasMoltenVK = fm.fileExists(atPath: moltenvkPath)
            let hasShared = fm.fileExists(atPath: d3dShared1) || fm.fileExists(atPath: d3dShared2)
            let hasWineDlls = fm.fileExists(atPath: wineDlls)
            
            if hasD3DMetal || hasMoltenVK || hasShared || hasWineDlls {
                let sharedPath = fm.fileExists(atPath: d3dShared1) ? d3dShared1 : (fm.fileExists(atPath: d3dShared2) ? d3dShared2 : nil)
                let frameworkPath = (libDir as NSString).appendingPathComponent("external/D3DMetal.framework")
                
                let version = extractVersion(from: volName)
                
                return GPTKPaths(
                    volumeRoot: volRoot,
                    libDir: libDir,
                    d3dmetal: hasD3DMetal ? d3dmetalPath : "",
                    moltenvk: hasMoltenVK ? moltenvkPath : "",
                    d3dShared: sharedPath,
                    frameworkPath: fm.fileExists(atPath: frameworkPath) ? frameworkPath : nil,
                    version: version
                )
            }
        }
        
        return nil
    }
    
    private func extractVersion(from name: String) -> String {
        let pattern = #"(\d+\.\d+(?:\.\d+)?)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) {
            if let range = Range(match.range(at: 1), in: name) {
                return String(name[range])
            }
        }
        return "2.x"
    }
}
