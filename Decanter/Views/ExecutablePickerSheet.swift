//
//  ExecutablePickerSheet.swift
//  Decanter
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct ExecutablePickerSheet: View {
    let bottle: Bottle
    let winePath: String
    let onRun: (String, [String]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedExePath: String = ""
    @State private var argumentsString: String = ""
    
    public init(bottle: Bottle, winePath: String, onRun: @escaping (String, [String]) -> Void) {
        self.bottle = bottle
        self.winePath = winePath
        self.onRun = onRun
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Run Windows Executable")
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
                    Text("Executable Path (.exe or installer)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    HStack {
                        TextField("Select an .exe file...", text: $selectedExePath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Choose File...") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = true
                            panel.canChooseDirectories = false
                            panel.allowedContentTypes = [.executable]
                            if panel.runModal() == .OK, let url = panel.url {
                                selectedExePath = url.path
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Command Line Arguments (Optional)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    TextField("e.g. -dx12 -fullscreen", text: $argumentsString)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Run Executable") {
                    let args = argumentsString
                        .split(separator: " ")
                        .map { String($0) }
                    onRun(selectedExePath, args)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedExePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480, height: 280)
    }
}
