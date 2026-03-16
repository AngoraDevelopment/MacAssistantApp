//
//  SystemActionExecutor.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation
import AppKit

@MainActor
final class SystemActionExecutor {

    func execute(_ action: AssistantAction) -> String {
        switch action {
        case .searchGoogle(let query):
            return searchGoogle(query)

        case .openWebsite(let url):
            return openWebsite(url)

        case .openApp(let name):
            return openApp(named: name)

        case .openFolder(let path):
            return openFolder(path)

        case .createFolder(let basePath, let folderName):
            return createFolder(basePath: basePath, folderName: folderName)

        case .quitApp(let name):
            return quitApp(named: name)

        case .shutdownMac:
            return shutdownMac()

        case .unknown:
            return "No entendí la acción."
        }
    }

    private func searchGoogle(_ query: String) -> String {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://www.google.com/search?q=\(encoded)") else {
            return "No pude construir la búsqueda."
        }

        NSWorkspace.shared.open(url)
        return "Busqué en Google: \(query)"
    }

    private func openWebsite(_ url: URL) -> String {
        NSWorkspace.shared.open(url)
        return "Abrí el sitio: \(url.absoluteString)"
    }

    private func openApp(named name: String) -> String {
        let normalized = NameNormalizer.normalizeApp(name)
        let workspace = NSWorkspace.shared

        // If the provided name looks like a bundle identifier, try that first
        if normalized.contains("."), let appURL = workspace.urlForApplication(withBundleIdentifier: normalized) {
            let config = NSWorkspace.OpenConfiguration()
            workspace.openApplication(at: appURL, configuration: config) { _, error in
                if let error {
                    print("Error abriendo app:", error.localizedDescription)
                }
            }
            return "Intenté abrir \(normalized)"
        }

        // Try to locate an app bundle by common install locations using the app name
        let candidateDirs: [URL] = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
        ]
        let candidateNames = ["\(normalized).app", "\(normalized.capitalized).app"]

        var foundAppURL: URL?
        for dir in candidateDirs {
            for candidate in candidateNames {
                let url = dir.appendingPathComponent(candidate, isDirectory: true)
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    foundAppURL = url
                    break
                }
            }
            if foundAppURL != nil { break }
        }

        if let appURL = foundAppURL {
            let config = NSWorkspace.OpenConfiguration()
            workspace.openApplication(at: appURL, configuration: config) { _, error in
                if let error {
                    print("Error abriendo app:", error.localizedDescription)
                }
            }
            return "Intenté abrir \(normalized)"
        }

        // As a last attempt, if the app is currently running, use its bundle identifier to resolve URL
        if let running = workspace.runningApplications.first(where: { $0.localizedName?.lowercased() == normalized.lowercased() }),
           let bundleID = running.bundleIdentifier,
           let appURL = workspace.urlForApplication(withBundleIdentifier: bundleID) {
            let config = NSWorkspace.OpenConfiguration()
            workspace.openApplication(at: appURL, configuration: config) { _, error in
                if let error {
                    print("Error abriendo app:", error.localizedDescription)
                }
            }
            return "Intenté abrir \(normalized)"
        }

        return "No encontré la app \(normalized)"
    }

    private func openFolder(_ path: String) -> String {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return "La carpeta no existe: \(expandedPath)"
        }

        NSWorkspace.shared.open(url)
        return "Abrí la carpeta: \(expandedPath)"
    }

    private func createFolder(basePath: String, folderName: String?) -> String {
        let expandedBasePath = NSString(string: basePath).expandingTildeInPath

        let finalPath: String
        if let folderName, !folderName.isEmpty {
            finalPath = (expandedBasePath as NSString).appendingPathComponent(folderName)
        } else {
            finalPath = expandedBasePath
        }

        do {
            try FileManager.default.createDirectory(
                atPath: finalPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
            return "Carpeta creada: \(finalPath)"
        } catch {
            return "No pude crear la carpeta: \(error.localizedDescription)"
        }
    }

    private func quitApp(named name: String) -> String {
        let normalized = NameNormalizer.normalizeApp(name)
        let runningApps = NSWorkspace.shared.runningApplications

        guard let app = runningApps.first(where: {
            $0.localizedName?.lowercased() == normalized.lowercased()
        }) else {
            return "La app \(normalized) no está abierta."
        }

        let ok = app.terminate()
        return ok ? "Intenté cerrar \(normalized)" : "No pude cerrar \(normalized)"
    }

    private func shutdownMac() -> String {
        // Esto usa AppleScript vía osascript.
        // Mejor úsalo solo si antes confirmas con el usuario.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to shut down"]

        do {
            try process.run()
            return "Intenté apagar la Mac."
        } catch {
            return "No pude apagar la Mac: \(error.localizedDescription)"
        }
    }
}
