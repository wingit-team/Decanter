//
//  BottleDetailView.swift
//  Decanter
//

import SwiftUI
import AppKit

public struct BottleDetailView: View {
    @ObservedObject var bottleManager: BottleManager
    @ObservedObject var setupManager: EnvironmentSetupManager
    @Binding var bottle: Bottle
    
    @State private var consoleLogs: String = ""
    @State private var isConsoleExpanded: Bool = false
    @State private var showExePicker: Bool = false
    @State private var isRunningProcess: Bool = false
    
    public init(bottleManager: BottleManager, setupManager: EnvironmentSetupManager, bottle: Binding<Bottle>) {
        self.bottleManager = bottleManager
        self.setupManager = setupManager
        self._bottle = bottle
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // ── Bottle Banner Header ──────────────────────────────────────────
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: "wineglass.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(bottle.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(bottle.arch)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(6)
                    }
                    
                    Text("\(bottle.windowsVersion.displayName) • Prefix: \(bottle.path)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: { showExePicker = true }) {
                    Label("Run Executable...", systemImage: "play.fill")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // ── Primary Quick Actions Bar ──────────────────────────────
                    HStack(spacing: 12) {
                        ActionTile(title: "Open C: Drive", icon: "folder.fill", color: .blue) {
                            let cDrive = (bottle.path as NSString).appendingPathComponent("drive_c")
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: cDrive)
                        }
                        
                        ActionTile(title: "Winecfg", icon: "gearshape.fill", color: .orange) {
                            runWineUtility("winecfg")
                        }
                        
                        ActionTile(title: "Control Panel", icon: "slider.horizontal.3", color: .green) {
                            runWineUtility("control")
                        }
                        
                        ActionTile(title: "Cmd Prompt", icon: "terminal.fill", color: .purple) {
                            runWineUtility("cmd")
                        }
                    }
                    
                    // ── Compatibility & Performance Switches ─────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COMPATIBILITY & GRAPHICS ENGINE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ToggleCard(
                                title: "D3DMetal (Apple GPTK)",
                                subtitle: "Translates Direct3D 11/12 to Metal shaders natively",
                                icon: "bolt.fill",
                                color: .purple,
                                isOn: Binding(
                                    get: { bottle.useD3DMetal },
                                    set: { val in
                                        bottle.useD3DMetal = val
                                        if val { bottle.useDXVK = false }
                                        bottleManager.updateBottle(bottle)
                                    }
                                )
                            )
                            
                            ToggleCard(
                                title: "DXVK (Vulkan -> Metal)",
                                subtitle: "Translates Direct3D 9/10/11 to Vulkan via MoltenVK",
                                icon: "atom",
                                color: .blue,
                                isOn: Binding(
                                    get: { bottle.useDXVK },
                                    set: { val in
                                        bottle.useDXVK = val
                                        if val { bottle.useD3DMetal = false }
                                        bottleManager.updateBottle(bottle)
                                    }
                                )
                            )
                            
                            ToggleCard(
                                title: "Esync (EventFD)",
                                subtitle: "Fast eventfd synchronization for Linux/macOS kernel",
                                icon: "bolt.horizontal.fill",
                                color: .green,
                                isOn: Binding(
                                    get: { bottle.useEsync },
                                    set: { val in
                                        bottle.useEsync = val
                                        bottleManager.updateBottle(bottle)
                                    }
                                )
                            )
                            
                            ToggleCard(
                                title: "Msync (Mach Semaphore)",
                                subtitle: "Mach-native primitive synchronization for Apple Silicon",
                                icon: "cpu",
                                color: .orange,
                                isOn: Binding(
                                    get: { bottle.useMsync },
                                    set: { val in
                                        bottle.useMsync = val
                                        bottleManager.updateBottle(bottle)
                                    }
                                )
                            )
                            
                            ToggleCard(
                                title: "Retina Mode (High DPI)",
                                subtitle: "Enables native high resolution scaling",
                                icon: "display",
                                color: .pink,
                                isOn: Binding(
                                    get: { bottle.useRetina },
                                    set: { val in
                                        bottle.useRetina = val
                                        bottleManager.updateBottle(bottle)
                                    }
                                )
                            )
                            
                            ToggleCard(
                                title: "Metal Performance HUD",
                                subtitle: "Displays FPS, frame time graph, and GPU statistics",
                                icon: "chart.xyaxis.line",
                                color: .cyan,
                                isOn: Binding(
                                    get: { bottle.showMetalHUD },
                                    set: { val in
                                        bottle.showMetalHUD = val
                                        bottleManager.updateBottle(bottle)
                                    }
                                )
                            )
                            
                            ToggleCard(
                                title: "Installer / Repack Fix Mode",
                                subtitle: "Enables LAA 4GB memory & stack protection for DODI/FitGirl setup.exe repacks",
                                icon: "shield.fill",
                                color: .yellow,
                                isOn: Binding(
                                    get: { bottle.useRepackCompatMode },
                                    set: { val in
                                        bottle.useRepackCompatMode = val
                                        bottleManager.updateBottle(bottle)
                                    }
                                )
                            )
                        }
                    }
                    
                    // ── Installed Applications Grid ───────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("INSTALLED APPLICATIONS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                bottle.installedApps = bottleManager.scanInstalledApps(in: bottle.path)
                                bottleManager.updateBottle(bottle)
                            }) {
                                Label("Rescan", systemImage: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if bottle.installedApps.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("No installed Windows applications detected yet.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Click 'Run Executable...' to install software or launch games.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 24)
                                Spacer()
                            }
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(12)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                                ForEach(bottle.installedApps) { app in
                                    AppTile(app: app) {
                                        let fullExe = (bottle.path as NSString).appendingPathComponent(app.relativeExePath)
                                        runExe(fullExe)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            
            // ── Live Output Console Drawer ──────────────────────────────────
            VStack(spacing: 0) {
                Divider()
                
                HStack {
                    Label("Console Output", systemImage: "terminal")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    if isRunningProcess {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.leading, 4)
                    }
                    
                    Spacer()
                    
                    Button("Clear") {
                        consoleLogs = ""
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    
                    Button(action: { withAnimation { isConsoleExpanded.toggle() } }) {
                        Image(systemName: isConsoleExpanded ? "chevron.down" : "chevron.up")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
                if isConsoleExpanded {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(consoleLogs.isEmpty ? "No console logs recorded." : consoleLogs)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .id("bottomLog")
                        }
                        .frame(height: 160)
                        .background(Color.black)
                        .onChange(of: consoleLogs) {
                            proxy.scrollTo("bottomLog", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showExePicker) {
            ExecutablePickerSheet(bottle: bottle, winePath: bottleManager.config.winePath) { exePath, args in
                showExePicker = false
                runExe(exePath, args: args)
            }
        }
    }
    
    private func runWineUtility(_ command: String) {
        isRunningProcess = true
        isConsoleExpanded = true
        Task {
            try? await WineRunner.shared.runExecutable(
                bottle: bottle,
                exePath: command,
                winePath: bottleManager.config.winePath,
                gptkPaths: setupManager.gptkInfo
            ) { line in
                consoleLogs.append(line)
            }
            isRunningProcess = false
        }
    }
    
    private func runExe(_ exePath: String, args: [String] = []) {
        isRunningProcess = true
        isConsoleExpanded = true
        Task {
            try? await WineRunner.shared.runExecutable(
                bottle: bottle,
                exePath: exePath,
                args: args,
                winePath: bottleManager.config.winePath,
                gptkPaths: setupManager.gptkInfo
            ) { line in
                consoleLogs.append(line)
            }
            isRunningProcess = false
        }
    }
}

// ── UI Components ─────────────────────────────────────────────────────────────

struct ActionTile: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct ToggleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(12)
    }
}

struct AppTile: View {
    let app: InstalledApp
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: app.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
                
                Text(app.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .padding(10)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
