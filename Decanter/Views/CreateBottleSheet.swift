//
//  CreateBottleSheet.swift
//  Decanter
//

import SwiftUI

public struct CreateBottleSheet: View {
    @ObservedObject var bottleManager: BottleManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var bottleName: String = "New Bottle"
    @State private var windowsVersion: WindowsVersion = .win10
    @State private var useD3DMetal: Bool = true
    @State private var isCreating: Bool = false
    
    public init(bottleManager: BottleManager) {
        self.bottleManager = bottleManager
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Create New Wine Bottle")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bottle Name")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    TextField("e.g. Steam Games, Cyberpunk", text: $bottleName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Windows Version Emulation")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Picker("Windows Version", selection: $windowsVersion) {
                        ForEach(WindowsVersion.allCases) { ver in
                            Text(ver.displayName).tag(ver)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Toggle(isOn: $useD3DMetal) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable D3DMetal (Apple GPTK)")
                            .fontWeight(.medium)
                        Text("Recommended for modern Direct3D 11/12 gaming performance on Apple Silicon")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    isCreating = true
                    Task {
                        _ = try? await bottleManager.createBottle(
                            name: bottleName,
                            windowsVersion: windowsVersion,
                            useD3DMetal: useD3DMetal
                        )
                        isCreating = false
                        dismiss()
                    }
                }) {
                    if isCreating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Create Bottle")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(bottleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440, height: 340)
    }
}
