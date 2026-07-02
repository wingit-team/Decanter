//
//  Bottle.swift
//  Decanter
//

import Foundation

/// Represents a Windows version emulation setting in Wine.
public enum WindowsVersion: String, Codable, CaseIterable, Identifiable {
    case win10 = "win10"
    case win11 = "win11"
    case win7 = "win7"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .win10: return "Windows 10"
        case .win11: return "Windows 11"
        case .win7: return "Windows 7"
        }
    }
}

/// Represents an installed application / executable detected inside a bottle.
public struct InstalledApp: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var relativeExePath: String // e.g. "drive_c/Program Files/Game/game.exe"
    public var iconName: String
    public var customArgs: String
    public var environmentOverrides: [String: String]
    
    public init(id: UUID = UUID(), name: String, relativeExePath: String, iconName: String = "gamecontroller", customArgs: String = "", environmentOverrides: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.relativeExePath = relativeExePath
        self.iconName = iconName
        self.customArgs = customArgs
        self.environmentOverrides = environmentOverrides
    }
}

/// Represents a Wine prefix ("Bottle") and its associated settings.
public struct Bottle: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var path: String // Absolute path to the bottle folder
    public var windowsVersion: WindowsVersion
    public var arch: String // "win64" or "win32"
    
    // Graphics & Performance Toggles
    public var useD3DMetal: Bool // Apple GPTK (D3DMetal)
    public var useDXVK: Bool // DXVK (Direct3D to Vulkan)
    public var useEsync: Bool // EventFD synchronization
    public var useMsync: Bool // Mach semaphore synchronization
    public var useRetina: Bool // High-DPI scaling mode
    public var showMetalHUD: Bool // MTL_HUD_ENABLED overlay
    public var useRepackCompatMode: Bool // Repack & Large Address Aware compatibility
    
    public var gptkInjected: Bool
    public var createdDate: Date
    public var installedApps: [InstalledApp]
    
    public init(
        id: UUID = UUID(),
        name: String,
        path: String,
        windowsVersion: WindowsVersion = .win10,
        arch: String = "win64",
        useD3DMetal: Bool = true,
        useDXVK: Bool = false,
        useEsync: Bool = true,
        useMsync: Bool = true,
        useRetina: Bool = true,
        showMetalHUD: Bool = false,
        useRepackCompatMode: Bool = true,
        gptkInjected: Bool = false,
        createdDate: Date = Date(),
        installedApps: [InstalledApp] = []
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.windowsVersion = windowsVersion
        self.arch = arch
        self.useD3DMetal = useD3DMetal
        self.useDXVK = useDXVK
        self.useEsync = useEsync
        self.useMsync = useMsync
        self.useRetina = useRetina
        self.showMetalHUD = showMetalHUD
        self.useRepackCompatMode = useRepackCompatMode
        self.gptkInjected = gptkInjected
        self.createdDate = createdDate
        self.installedApps = installedApps
    }
}
