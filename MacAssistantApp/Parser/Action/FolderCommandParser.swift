//
//  FolderCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct FolderCommandParser: TraceableAssistantActionParsing {
    let memoryStore: MemoryStore
    let parserName: String = "FolderCommandParser"

    func parse(_ input: String) -> AssistantAction? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        if let action = parseOpenFolder(raw: raw, lower: lower) {
            return action
        }

        if let action = parseCreateFolder(raw: raw, lower: lower) {
            return action
        }

        return nil
    }

    private func parseOpenFolder(raw: String, lower: String) -> AssistantAction? {
        let explicitPrefixes = [
            "abre la carpeta ",
            "abre carpeta ",
            "abrir carpeta ",
            "open folder "
        ]

        for prefix in explicitPrefixes where lower.hasPrefix(prefix) {
            let value = String(raw.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !value.isEmpty else { return nil }
            return resolveFolderValue(value)
        }

        let genericPrefixes = [
            "abre ",
            "abrir ",
            "open "
        ]

        for prefix in genericPrefixes where lower.hasPrefix(prefix) {
            let value = String(raw.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !value.isEmpty else { return nil }

            if memoryStore.folderPath(for: value) != nil {
                return resolveFolderValue(value)
            }

            if value.hasPrefix("/") || value.hasPrefix("~") {
                return resolveFolderValue(value)
            }
        }

        return nil
    }

    private func parseCreateFolder(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "crea una carpeta llamada ",
            "crear una carpeta llamada ",
            "haz una carpeta llamada "
        ]

        for prefix in prefixes where lower.hasPrefix(prefix) {
            let value = String(raw.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !value.isEmpty else { return nil }

            return .createFolder(
                basePath: FileManager.default.homeDirectoryForCurrentUser.path,
                folderName: value
            )
        }

        return nil
    }

    private func resolveFolderValue(_ value: String) -> AssistantAction {
        if let folderAlias = memoryStore.folderPath(for: value) {
            return .openFolder(path: folderAlias)
        }

        return .openFolder(path: PathNormalizer.normalizeFolderPath(value))
    }
}
