//
//  AppConfig.swift
//  Decanter
//

import Foundation

/// Application preferences and environment paths configuration.
public struct AppConfig: Codable {
    public var winePath: String
    public var bottlesDirectory: String
    public var customGPTKPath: String?
    public var autoInstallMissingTools: Bool
    
    public static var defaultBottlesDirectory: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Decanter/Bottles").path
    }
    
    nonisolated public static var defaultWinePath: String {
        let candidates = [
            "/opt/homebrew/bin/wine",
            "/usr/local/bin/wine",
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64"
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return "/opt/homebrew/bin/wine"
    }
    
    public init(
        winePath: String = AppConfig.defaultWinePath,
        bottlesDirectory: String = AppConfig.defaultBottlesDirectory,
        customGPTKPath: String? = nil,
        autoInstallMissingTools: Bool = true
    ) {
        self.winePath = winePath
        self.bottlesDirectory = bottlesDirectory
        self.customGPTKPath = customGPTKPath
        self.autoInstallMissingTools = autoInstallMissingTools
    }
}
