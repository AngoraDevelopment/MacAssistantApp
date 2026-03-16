//
//  AssistantActionValidator.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/10/26.
//

import Foundation
import AppKit

struct AssistantActionValidator {
    let memoryStore: MemoryStore
    let installedAppsIndex: InstalledAppsIndex
    let userFilesIndex: UserFilesIndex

    init(memoryStore: MemoryStore, installedAppsIndex: InstalledAppsIndex, userFilesIndex: UserFilesIndex) {
        self.memoryStore = memoryStore
        self.installedAppsIndex = installedAppsIndex
        self.userFilesIndex = userFilesIndex
    }
    
    func validate(_ action: AssistantAction) -> ValidationResult {
        switch action {
        case .openFolder(let path):
            return validateOpenFolder(path)
            
        case .openFile(let path):
            return validateOpenFile(path)

        case .findFile(let query):
            return validateFindFile(query)
            
        case .createFolder(let basePath, let folderName):
            return validateCreateFolder(basePath: basePath, folderName: folderName)

        case .openApp(let name):
            return validateOpenApp(name)

        case .openWebsite(let url):
            return validateOpenWebsite(url)

        case .rememberFolderAlias(let alias, let path):
            return validateRememberFolderAlias(alias: alias, path: path)

        case .rememberAppAlias(let alias, let appName):
            return validateRememberAppAlias(alias: alias, appName: appName)

        case .rememberWebsiteAlias(let alias, let url):
            return validateRememberWebsiteAlias(alias: alias, url: url)

        default:
            return .valid
        }
    }

    private func validateOpenFolder(_ path: String) -> ValidationResult {
        let expandedPath = NSString(string: path).expandingTildeInPath
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory)

        guard exists else {
            return .invalid(message: "La carpeta no existe: \(expandedPath)")
        }

        guard isDirectory.boolValue else {
            return .invalid(message: "La ruta no es una carpeta: \(expandedPath)")
        }

        return .valid
    }

    private func validateCreateFolder(basePath: String, folderName: String?) -> ValidationResult {
        let expandedBasePath = NSString(string: basePath).expandingTildeInPath
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: expandedBasePath, isDirectory: &isDirectory)

        guard exists else {
            return .invalid(message: "La carpeta base no existe: \(expandedBasePath)")
        }

        guard isDirectory.boolValue else {
            return .invalid(message: "La ruta base no es una carpeta: \(expandedBasePath)")
        }

        if let folderName, !folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let finalPath = (expandedBasePath as NSString).appendingPathComponent(folderName)
            if FileManager.default.fileExists(atPath: finalPath) {
                return .warning(message: "La carpeta ya existe: \(finalPath). Se puede reutilizar o sobrescribir lógicamente.")
            }
        }

        return .valid
    }

    private func validateOpenApp(_ name: String) -> ValidationResult {
        let resolver = AppResolver(installedAppsIndex: installedAppsIndex)

        if resolver.resolve(name) != nil {
            return .valid
        }

        let suggestions = resolver.suggestions(for: name).map(\.displayName)

        if suggestions.isEmpty {
            return .invalid(message: "No encontré una app llamada \(name).")
        } else {
            return .invalid(
                message: "No encontré una app llamada \(name). Quizá quisiste decir: \(suggestions.joined(separator: ", "))."
            )
        }
    }

    private func bundleIdentifier(for appName: String) -> String? {
        switch appName.lowercased() {
        case "safari":
            return "com.apple.Safari"
        case "xcode":
            return "com.apple.dt.Xcode"
        case "finder":
            return "com.apple.finder"
        case "terminal":
            return "com.apple.Terminal"
        case "google chrome":
            return "com.google.Chrome"
        case "discord":
            return "com.hnc.Discord"
        case "steam":
            return "com.valvesoftware.steam"
        case "spotify":
            return "com.spotify.client"
        default:
            return nil
        }
    }

    private func validateOpenWebsite(_ url: URL) -> ValidationResult {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return .invalid(message: "La URL no es válida para abrirse en navegador: \(url.absoluteString)")
        }

        guard url.host != nil else {
            return .invalid(message: "La URL no tiene dominio válido: \(url.absoluteString)")
        }

        return .valid
    }

    private func validateRememberFolderAlias(alias: String, path: String) -> ValidationResult {
        let cleanAlias = alias.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let expandedPath = NSString(string: path).expandingTildeInPath

        guard !cleanAlias.isEmpty else {
            return .invalid(message: "El alias no puede estar vacío.")
        }

        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory)

        guard exists, isDirectory.boolValue else {
            return .invalid(message: "La carpeta no existe o no es válida: \(expandedPath)")
        }

        if memoryStore.folderPath(for: cleanAlias) != nil ||
            memoryStore.appName(for: cleanAlias) != nil ||
            memoryStore.websiteURL(for: cleanAlias) != nil {
            return .warning(message: "El alias '\(cleanAlias)' ya existe. Si continúas, se sobrescribirá.")
        }

        return .valid
    }

    private func validateRememberAppAlias(alias: String, appName: String) -> ValidationResult {
        let cleanAlias = alias.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedApp = NameNormalizer.normalizeApp(appName)

        guard !cleanAlias.isEmpty else {
            return .invalid(message: "El alias no puede estar vacío.")
        }

        guard NSWorkspace.shared.fullPath(forApplication: normalizedApp) != nil else {
            return .invalid(message: "No encontré la app \(normalizedApp)")
        }

        if memoryStore.folderPath(for: cleanAlias) != nil ||
            memoryStore.appName(for: cleanAlias) != nil ||
            memoryStore.websiteURL(for: cleanAlias) != nil {
            return .warning(message: "El alias '\(cleanAlias)' ya existe. Si continúas, se sobrescribirá.")
        }

        return .valid
    }

    private func validateRememberWebsiteAlias(alias: String, url: String) -> ValidationResult {
        let cleanAlias = alias.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !cleanAlias.isEmpty else {
            return .invalid(message: "El alias no puede estar vacío.")
        }

        guard let parsedURL = URL(string: url),
              let scheme = parsedURL.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              parsedURL.host != nil else {
            return .invalid(message: "La URL no es válida: \(url)")
        }

        if memoryStore.folderPath(for: cleanAlias) != nil ||
            memoryStore.appName(for: cleanAlias) != nil ||
            memoryStore.websiteURL(for: cleanAlias) != nil {
            return .warning(message: "El alias '\(cleanAlias)' ya existe. Si continúas, se sobrescribirá.")
        }

        return .valid
    }
    private func validateOpenFile(_ path: String) -> ValidationResult {
        let expandedPath = NSString(string: path).expandingTildeInPath

        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return .invalid(message: "No encontré ese archivo.")
        }

        return .valid
    }

    private func validateFindFile(_ query: String) -> ValidationResult {
        let resolver = FileResolver(userFilesIndex: userFilesIndex)

        if resolver.resolve(query) != nil {
            return .valid
        }

        let suggestions = resolver.suggestions(for: query).map(\.fileName)

        if suggestions.isEmpty {
            return .invalid(message: "No encontré un archivo que coincida con \(query).")
        } else {
            return .invalid(
                message: "No encontré un archivo exacto para \(query). Quizá quisiste decir: \(suggestions.joined(separator: ", "))."
            )
        }
    }
}
