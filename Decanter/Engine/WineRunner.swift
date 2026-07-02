//
//  WineRunner.swift
//  Decanter
//

import Foundation

@MainActor
public class WineRunner {
    public static let shared = WineRunner()
    
    private var activeProcesses: [UUID: Process] = [:]
    
    /// Executes a Windows executable or Wine utility in a given bottle.
    public func runExecutable(
        bottle: Bottle,
        exePath: String,
        args: [String] = [],
        winePath: String = AppConfig.defaultWinePath,
        gptkPaths: GPTKPaths? = nil,
        extraEnv: [String: String] = [:],
        logHandler: @escaping (String) -> Void
    ) async throws {
        let envManager = WineEnvironmentManager()
        let env = envManager.buildEnvironment(bottle: bottle, gptk: gptkPaths, extraEnv: extraEnv)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: winePath)
        process.arguments = [exePath] + args
        process.environment = env
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        let processID = UUID()
        activeProcesses[processID] = process
        
        logHandler("[Decanter] Launching '\(exePath)' with Wine (\(winePath))...\n")
        logHandler("[Decanter] WINEPREFIX=\(bottle.path)\n")
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let line = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    logHandler(line)
                }
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { [weak self] proc in
                Task { @MainActor in
                    self?.activeProcesses.removeValue(forKey: processID)
                }
                logHandler("\n[Decanter] Process terminated with exit code \(proc.terminationStatus).\n")
                continuation.resume(returning: ())
            }
            
            do {
                try process.run()
            } catch {
                activeProcesses.removeValue(forKey: processID)
                logHandler("[Decanter Error] Failed to start process: \(error.localizedDescription)\n")
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Terminates all running processes started by this runner.
    public func killAllRunningProcesses() {
        for (_, proc) in activeProcesses {
            proc.terminate()
        }
        activeProcesses.removeAll()
    }
}
