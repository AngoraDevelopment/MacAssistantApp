//
//  AppExecutionService.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import AppKit
import Foundation

@MainActor
final class AppExecutionService {
    private let installedAppsIndex: InstalledAppsIndex

    init(installedAppsIndex: InstalledAppsIndex) {
        self.installedAppsIndex = installedAppsIndex
    }

    func openApp(named name: String) -> AssistantExecutionResult {
        let resolver = AppResolver(installedAppsIndex: installedAppsIndex)

        guard let app = resolver.resolve(name) else {
            let suggestions = resolver.suggestions(for: name).map(\.displayName)
            let suffix = suggestions.isEmpty ? "" : " Posibles coincidencias: \(suggestions.joined(separator: ", "))."

            return AssistantExecutionResult(
                success: false,
                technicalMessage: "No se encontró app para '\(name)'",
                userMessage: "No pude encontrar una app llamada \(name).\(suffix)"
            )
        }

        let workspace = NSWorkspace.shared
        let config = NSWorkspace.OpenConfiguration()

        workspace.openApplication(at: app.appURL, configuration: config) { runningApp, error in
            if let error {
                print("Error abriendo \(app.displayName): \(error.localizedDescription)")
                return
            }

            guard let runningApp else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                _ = runningApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            }
        }

        return AssistantExecutionResult(
            success: true,
            technicalMessage: "App abierta → \(app.displayName) | \(app.appURLPath)",
            userMessage: "Listo, intenté abrir \(app.displayName)."
        )
    }

    func quitApp(named name: String) -> AssistantExecutionResult {
        let normalized = NameNormalizer.normalizeApp(name)

        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            ($0.localizedName ?? "").lowercased() == normalized.lowercased()
        }) else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "App no estaba abierta → \(normalized)",
                userMessage: "No vi \(normalized) abierta."
            )
        }

        let ok = app.terminate()

        return AssistantExecutionResult(
            success: ok,
            technicalMessage: "Terminate \(normalized) → \(ok)",
            userMessage: ok ? "Listo, intenté cerrar \(normalized)." : "No pude cerrar \(normalized)."
        )
    }

    func shutdownMac() -> AssistantExecutionResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to shut down"]

        do {
            try process.run()
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "Solicitud de apagado enviada",
                userMessage: "Listo, intenté apagar la Mac."
            )
        } catch {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "Error apagando Mac → \(error.localizedDescription)",
                userMessage: "No pude apagar la Mac."
            )
        }
    }
}
