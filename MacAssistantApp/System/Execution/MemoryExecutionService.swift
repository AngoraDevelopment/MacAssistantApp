//
//  MemoryExecutionService.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

@MainActor
final class MemoryExecutionService {
    private let memoryStore: MemoryStore

    init(memoryStore: MemoryStore) {
        self.memoryStore = memoryStore
    }

    func rememberFolderAlias(alias: String, path: String) -> AssistantExecutionResult {
        memoryStore.rememberFolderAlias(alias: alias, path: path)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias carpeta guardado → \(alias) = \(path)",
            userMessage: "Listo, guardé ese alias de carpeta."
        )
    }

    func rememberAppAlias(alias: String, appName: String) -> AssistantExecutionResult {
        memoryStore.rememberAppAlias(alias: alias, appName: appName)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias app guardado → \(alias) = \(appName)",
            userMessage: "Listo, guardé ese alias de app."
        )
    }

    func rememberWebsiteAlias(alias: String, url: String) -> AssistantExecutionResult {
        memoryStore.rememberWebsiteAlias(alias: alias, url: url)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias web guardado → \(alias) = \(url)",
            userMessage: "Listo, guardé ese alias de sitio."
        )
    }

    func forgetFolderAlias(_ alias: String) -> AssistantExecutionResult {
        memoryStore.forgetFolderAlias(alias)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias carpeta eliminado → \(alias)",
            userMessage: "Listo, olvidé ese alias."
        )
    }

    func forgetAppAlias(_ alias: String) -> AssistantExecutionResult {
        memoryStore.forgetAppAlias(alias)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias app eliminado → \(alias)",
            userMessage: "Listo, olvidé ese alias."
        )
    }

    func forgetWebsiteAlias(_ alias: String) -> AssistantExecutionResult {
        memoryStore.forgetWebsiteAlias(alias)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias web eliminado → \(alias)",
            userMessage: "Listo, olvidé ese alias."
        )
    }

    func listMemory() -> AssistantExecutionResult {
        let folders = memoryStore.allFolderAliases()
        let apps = memoryStore.allAppAliases()
        let websites = memoryStore.allWebsiteAliases()

        if folders.isEmpty && apps.isEmpty && websites.isEmpty {
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "Memoria consultada → vacía",
                userMessage: "Ahora mismo no tengo nada guardado en memoria."
            )
        }

        var lines: [String] = []

        if !folders.isEmpty {
            lines.append("Carpetas:")
            for key in folders.keys.sorted() {
                if let value = folders[key] { lines.append("- \(key) → \(value)") }
            }
        }

        if !apps.isEmpty {
            if !lines.isEmpty { lines.append("") }
            lines.append("Apps:")
            for key in apps.keys.sorted() {
                if let value = apps[key] { lines.append("- \(key) → \(value)") }
            }
        }

        if !websites.isEmpty {
            if !lines.isEmpty { lines.append("") }
            lines.append("Sitios:")
            for key in websites.keys.sorted() {
                if let value = websites[key] { lines.append("- \(key) → \(value)") }
            }
        }

        let formatted = lines.joined(separator: "\n")

        return AssistantExecutionResult(
            success: true,
            technicalMessage: formatted,
            userMessage: "Esto es lo que recuerdo ahora mismo:\n\n\(formatted)"
        )
    }

    func listFolderAliases() -> AssistantExecutionResult { listSimple(memoryStore.allFolderAliases(), title: "Carpetas guardadas") }
    func listAppAliases() -> AssistantExecutionResult { listSimple(memoryStore.allAppAliases(), title: "Apps guardadas") }
    func listWebsiteAliases() -> AssistantExecutionResult { listSimple(memoryStore.allWebsiteAliases(), title: "Sitios guardados") }

    func clearMemory() -> AssistantExecutionResult {
        memoryStore.clearAll()
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Memoria borrada",
            userMessage: "Listo, borré toda la memoria."
        )
    }

    private func listSimple(_ dictionary: [String: String], title: String) -> AssistantExecutionResult {
        if dictionary.isEmpty {
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "\(title) → vacío",
                userMessage: "No tengo nada guardado en esa sección."
            )
        }

        let lines = dictionary.keys.sorted().compactMap { key in
            dictionary[key].map { "- \(key) → \($0)" }
        }

        return AssistantExecutionResult(
            success: true,
            technicalMessage: lines.joined(separator: "\n"),
            userMessage: "\(title):\n" + lines.joined(separator: "\n")
        )
    }
}
