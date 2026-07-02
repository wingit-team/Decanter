//
//  EnvironmentSetupManager.swift
//  Decanter
//

import Foundation
import Combine

@MainActor
public class EnvironmentSetupManager: ObservableObject {
    @Published public var isWineInstalled: Bool = false
    @Published public var detectedWinePath: String = ""
    @Published public var isGPTKDetected: Bool = false
    @Published public var gptkInfo: GPTKPaths? = nil
    @Published public var isHomebrewInstalled: Bool = false
    @Published public var isInstallingTools: Bool = false
    @Published public var installStatusMessage: String = ""
    
    public init() {
        checkEnvironment()
    }
    
    public func checkEnvironment() {
        let fm = FileManager.default
        let brewPath = "/opt/homebrew/bin/brew"
        let usrBrewPath = "/usr/local/bin/brew"
        isHomebrewInstalled = fm.fileExists(atPath: brewPath) || fm.fileExists(atPath: usrBrewPath)
        
        let wineCandidates = [
            "/opt/homebrew/bin/wine",
            "/usr/local/bin/wine",
            "/opt/homebrew/bin/wine64",
            "/usr/local/bin/wine64"
        ]
        
        var foundWine = false
        for path in wineCandidates {
            if fm.fileExists(atPath: path) {
                isWineInstalled = true
                detectedWinePath = path
                foundWine = true
                break
            }
        }
        if !foundWine {
            isWineInstalled = false
            detectedWinePath = ""
        }
        
        if let gptk = GPTKDetector.shared.detectGPTK() {
            isGPTKDetected = true
            gptkInfo = gptk
        } else {
            isGPTKDetected = false
            gptkInfo = nil
        }
    }
    
    /// Automatically attempts to install Wine via Homebrew if missing.
    public func installWineViaHomebrew() async {
        guard isHomebrewInstalled else {
            DispatchQueue.main.async {
                self.installStatusMessage = "Homebrew is not installed. Please install Homebrew from https://brew.sh first."
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isInstallingTools = true
            self.installStatusMessage = "Installing wine-stable via Homebrew... (this may take a few minutes)"
        }
        
        let brewBinary = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brewBinary)
        process.arguments = ["install", "--cask", "wine-stable"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            DispatchQueue.main.async {
                self.isInstallingTools = false
                if process.terminationStatus == 0 {
                    self.installStatusMessage = "Successfully installed Wine!"
                    self.checkEnvironment()
                } else {
                    self.installStatusMessage = "Failed to install Wine via Homebrew. Exit code: \(process.terminationStatus)"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isInstallingTools = false
                self.installStatusMessage = "Installation error: \(error.localizedDescription)"
            }
        }
    }
}
