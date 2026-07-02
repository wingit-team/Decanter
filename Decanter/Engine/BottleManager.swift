//
//  BottleManager.swift
//  Decanter
//

import Foundation
import Combine
import SwiftUI

@MainActor
public class BottleManager: ObservableObject {
    @Published public var bottles: [Bottle] = []
    @Published public var selectedBottleID: UUID? = nil
    @Published public var config: AppConfig
    
    private let fm = FileManager.default
    
    public func binding(for bottleID: UUID) -> Binding<Bottle> {
        Binding(
            get: {
                self.bottles.first(where: { $0.id == bottleID }) ?? Bottle(name: "Placeholder", path: "")
            },
            set: { updated in
                if let index = self.bottles.firstIndex(where: { $0.id == bottleID }) {
                    self.bottles[index] = updated
                    self.saveBottleMetadata(updated)
                }
            }
        )
    }
    
    public var selectedBottle: Bottle? {
        get {
            guard let id = selectedBottleID else { return bottles.first }
            return bottles.first(where: { $0.id == id })
        }
        set {
            selectedBottleID = newValue?.id
        }
    }
    
    public init() {
        self.config = AppConfig()
        loadBottles()
    }
    
    /// Scans the default bottles directory for existing bottles and loads their metadata.
    public func loadBottles() {
        let bottlesDir = config.bottlesDirectory
        try? fm.createDirectory(atPath: bottlesDir, withIntermediateDirectories: true)
        
        guard let entries = try? fm.contentsOfDirectory(atPath: bottlesDir) else {
            return
        }
        
        var loadedBottles: [Bottle] = []
        
        for name in entries {
            let bottlePath = (bottlesDir as NSString).appendingPathComponent(name)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: bottlePath, isDirectory: &isDir), isDir.boolValue {
                let metadataPath = (bottlePath as NSString).appendingPathComponent("decanter.json")
                if fm.fileExists(atPath: metadataPath),
                   let data = try? Data(contentsOf: URL(fileURLWithPath: metadataPath)),
                   let bottle = try? JSONDecoder().decode(Bottle.self, from: data) {
                    var updatedBottle = bottle
                    updatedBottle.installedApps = scanInstalledApps(in: bottlePath)
                    loadedBottles.append(updatedBottle)
                } else {
                    // Create default bottle wrapper for existing folder
                    let bottle = Bottle(name: name, path: bottlePath)
                    loadedBottles.append(bottle)
                    saveBottleMetadata(bottle)
                }
            }
        }
        
        self.bottles = loadedBottles
        if selectedBottleID == nil {
            selectedBottleID = loadedBottles.first?.id
        }
    }
    
    /// Creates a new Wine bottle/prefix directory on disk.
    public func createBottle(name: String, windowsVersion: WindowsVersion = .win10, arch: String = "win64", useD3DMetal: Bool = true) async throws -> Bottle {
        let safeName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let bottlePath = (config.bottlesDirectory as NSString).appendingPathComponent(safeName)
        
        try fm.createDirectory(atPath: bottlePath, withIntermediateDirectories: true)
        let cDrive = (bottlePath as NSString).appendingPathComponent("drive_c/windows/system32")
        try fm.createDirectory(atPath: cDrive, withIntermediateDirectories: true)
        
        var bottle = Bottle(
            name: safeName,
            path: bottlePath,
            windowsVersion: windowsVersion,
            arch: arch,
            useD3DMetal: useD3DMetal
        )
        
        // Auto-inject GPTK if detected and D3DMetal is enabled
        if useD3DMetal, let gptk = GPTKDetector.shared.detectGPTK() {
            if let injected = try? await GPTKInjector.shared.injectGPTK(bottle: bottle, gptk: gptk, winePath: config.winePath) {
                bottle = injected
            }
        }
        
        saveBottleMetadata(bottle)
        
        DispatchQueue.main.async {
            self.bottles.append(bottle)
            self.selectedBottleID = bottle.id
        }
        
        return bottle
    }
    
    /// Updates bottle settings and saves to decanter.json metadata file.
    public func updateBottle(_ bottle: Bottle) {
        if let index = bottles.firstIndex(where: { $0.id == bottle.id }) {
            bottles[index] = bottle
            saveBottleMetadata(bottle)
        }
    }
    
    /// Deletes a bottle from disk and removes it from state.
    public func deleteBottle(_ bottle: Bottle) {
        try? fm.removeItem(atPath: bottle.path)
        bottles.removeAll(where: { $0.id == bottle.id })
        if selectedBottleID == bottle.id {
            selectedBottleID = bottles.first?.id
        }
    }
    
    /// Saves bottle metadata JSON inside bottle folder (`decanter.json`).
    public func saveBottleMetadata(_ bottle: Bottle) {
        let metadataPath = (bottle.path as NSString).appendingPathComponent("decanter.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(bottle) {
            try? data.write(to: URL(fileURLWithPath: metadataPath))
        }
    }
    
    /// Scans bottle drive_c for installed .exe executables.
    public func scanInstalledApps(in bottlePath: String) -> [InstalledApp] {
        let cDrive = (bottlePath as NSString).appendingPathComponent("drive_c")
        var apps: [InstalledApp] = []
        
        guard fm.fileExists(atPath: cDrive) else { return apps }
        
        let targetDirs = [
            (cDrive as NSString).appendingPathComponent("Program Files"),
            (cDrive as NSString).appendingPathComponent("Program Files (x86)")
        ]
        
        let skipKeywords = ["unins", "setup", "dxsetup", "vcredist", "crashreporter", "helper"]
        
        for dir in targetDirs {
            if let enumerator = fm.enumerator(atPath: dir) {
                for case let file as String in enumerator {
                    if file.hasSuffix(".exe") {
                        let fileName = (file as NSString).lastPathComponent.lowercased()
                        if skipKeywords.contains(where: { fileName.contains($0) }) {
                            continue
                        }
                        let relativePath = "drive_c/" + (((dir as NSString).lastPathComponent as NSString).appendingPathComponent(file))
                        let appName = ((file as NSString).lastPathComponent as NSString).deletingPathExtension
                        apps.append(InstalledApp(name: appName, relativeExePath: relativePath))
                    }
                }
            }
        }
        
        return Array(apps.prefix(12))
    }
}
