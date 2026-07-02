//
//  ContentView.swift
//  Decanter
//

import SwiftUI

public enum NavigationSelection: Hashable {
    case bottle(UUID)
    case settings
}

public struct ContentView: View {
    @StateObject private var bottleManager = BottleManager()
    @StateObject private var setupManager = EnvironmentSetupManager()
    
    @State private var selection: NavigationSelection? = nil
    @State private var showCreateBottleSheet: Bool = false
    
    public var body: some View {
        NavigationSplitView {
            // ── Sidebar ────────────────────────────────────────────────────────
            VStack(spacing: 0) {
                List(selection: $selection) {
                    Section(header: Text("WINE BOTTLES")) {
                        ForEach($bottleManager.bottles) { $bottle in
                            NavigationLink(value: NavigationSelection.bottle(bottle.id)) {
                                HStack(spacing: 10) {
                                    Image(systemName: "wineglass")
                                        .foregroundColor(.purple)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bottle.name)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        
                                        Text(bottle.useD3DMetal ? "D3DMetal (GPTK)" : (bottle.useDXVK ? "DXVK" : "Standard"))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .contextMenu {
                                Button("Open C: Drive") {
                                    let cDrive = (bottle.path as NSString).appendingPathComponent("drive_c")
                                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: cDrive)
                                }
                                Divider()
                                Button("Delete Bottle", role: .destructive) {
                                    bottleManager.deleteBottle(bottle)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("PREFERENCES")) {
                        NavigationLink(value: NavigationSelection.settings) {
                            Label("Settings & Tools", systemImage: "gear")
                        }
                    }
                }
                .listStyle(.sidebar)
                
                Divider()
                
                // ── Sidebar Footer Status Banner ───────────────────────────────
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: setupManager.isWineInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(setupManager.isWineInstalled ? .green : .red)
                        Text(setupManager.isWineInstalled ? "Wine Ready" : "Wine Missing")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: setupManager.isGPTKDetected ? "bolt.circle.fill" : "info.circle")
                            .foregroundColor(setupManager.isGPTKDetected ? .purple : .secondary)
                        Text(setupManager.isGPTKDetected ? "GPTK Active (\(setupManager.gptkInfo?.version ?? ""))" : "GPTK Not Detected")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showCreateBottleSheet = true }) {
                        Label("New Bottle", systemImage: "plus")
                    }
                    .help("Create New Wine Bottle")
                }
            }
        } detail: {
            // ── Detail Pane ──────────────────────────────────────────────────
            switch selection {
            case .bottle(let bottleID):
                if bottleManager.bottles.contains(where: { $0.id == bottleID }) {
                    BottleDetailView(
                        bottleManager: bottleManager,
                        setupManager: setupManager,
                        bottle: bottleManager.binding(for: bottleID)
                    )
                } else {
                    EmptySelectionView(showCreateSheet: $showCreateBottleSheet)
                }
                
            case .settings:
                SettingsView(bottleManager: bottleManager, setupManager: setupManager)
                
            case nil:
                if let firstID = bottleManager.bottles.first?.id {
                    BottleDetailView(
                        bottleManager: bottleManager,
                        setupManager: setupManager,
                        bottle: bottleManager.binding(for: firstID)
                    )
                } else {
                    EmptySelectionView(showCreateSheet: $showCreateBottleSheet)
                }
            }
        }
        .sheet(isPresented: $showCreateBottleSheet) {
            CreateBottleSheet(bottleManager: bottleManager)
        }
        .onAppear {
            if selection == nil, let first = bottleManager.bottles.first {
                selection = .bottle(first.id)
            }
        }
    }
}

struct EmptySelectionView: View {
    @Binding var showCreateSheet: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wineglass")
                .font(.system(size: 64))
                .foregroundColor(.purple)
            
            Text("No Bottle Selected")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Select an existing Wine bottle from the sidebar, or create a new bottle to run Windows software.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            
            Button("Create New Bottle") {
                showCreateSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
    }
}

#Preview {
    ContentView()
}
