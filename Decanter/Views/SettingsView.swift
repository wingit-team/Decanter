//
//  SettingsView.swift
//  Decanter
//

import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var bottleManager: BottleManager
    @ObservedObject var setupManager: EnvironmentSetupManager
    
    @State private var winePath: String = ""
    @State private var bottlesDir: String = ""
    
    public init(bottleManager: BottleManager, setupManager: EnvironmentSetupManager) {
        self.bottleManager = bottleManager
        self.setupManager = setupManager
        self._winePath = State(initialValue: bottleManager.config.winePath)
        self._bottlesDir = State(initialValue: bottleManager.config.bottlesDirectory)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Decanter Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                // ── Wine Binary Path ──────────────────────────────────────────
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wine Binary Location")
                        .font(.headline)
                    
                    HStack {
                        TextField("Path to wine / wine64 executable", text: $winePath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Browse...") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = true
                            panel.canChooseDirectories = false
                            if panel.runModal() == .OK, let url = panel.url {
                                winePath = url.path
                                bottleManager.config.winePath = url.path
                            }
                        }
                    }
                    
                    if setupManager.isWineInstalled {
                        Label("Wine binary detected at: \(setupManager.detectedWinePath)", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Wine binary not found in standard paths", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            if setupManager.isInstallingTools {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text(setupManager.installStatusMessage)
                                        .font(.caption)
                                }
                            } else {
                                Button("Auto-Install Wine via Homebrew") {
                                    Task {
                                        await setupManager.installWineViaHomebrew()
                                    }
                                }
                                .font(.caption)
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
                
                Divider()
                
                // ── Apple GPTK Status ──────────────────────────────────────────
                VStack(alignment: .leading, spacing: 6) {
                    Text("Apple Game Porting Toolkit (GPTK)")
                        .font(.headline)
                    
                    if setupManager.isGPTKDetected, let gptk = setupManager.gptkInfo {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("GPTK Detected: \(gptk.version)", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                            
                            Text("Location: \(gptk.volumeRoot)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !gptk.d3dmetal.isEmpty {
                                Text("D3DMetal: \(gptk.d3dmetal)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color.purple.opacity(0.08))
                        .cornerRadius(10)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("No mounted GPTK volume or D3DMetal framework detected", systemImage: "info.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("To use D3DMetal graphics acceleration, mount Apple's Game Porting Toolkit DMG (version 2 or 3) from developer.apple.com.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.06))
                        .cornerRadius(10)
                    }
                }
                
                Divider()
                
                // ── Bottles Storage Path ──────────────────────────────────────
                VStack(alignment: .leading, spacing: 6) {
                    Text("Default Bottles Storage Directory")
                        .font(.headline)
                    
                    HStack {
                        TextField("Bottles Directory", text: $bottlesDir)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Browse...") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            if panel.runModal() == .OK, let url = panel.url {
                                bottlesDir = url.path
                                bottleManager.config.bottlesDirectory = url.path
                                bottleManager.loadBottles()
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(24)
    }
}
