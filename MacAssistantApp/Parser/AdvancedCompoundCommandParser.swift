//
//  Untitled.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct AdvancedCompoundCommandParser {

    func parse(
        _ input: String,
        memoryStore: MemoryStore,
        context: ConversationContext
    ) -> CompoundParsedCommand? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        if let command = parseOpenWebsiteAndSearch(raw: raw, lower: lower) {
            return command
        }

        if let command = parseOpenFolderAndCreateFolder(raw: raw, lower: lower, memoryStore: memoryStore) {
            return command
        }

        if let command = parseOpenFolderAndOpenApp(raw: raw, lower: lower, memoryStore: memoryStore) {
            return command
        }

        if let command = parseOpenAppAndOpenWebsite(raw: raw, lower: lower) {
            return command
        }

        if let command = parseOpenAppAndQuitApp(raw: raw, lower: lower) {
            return command
        }

        if let command = parseOpenFolderAndSearchGoogle(raw: raw, lower: lower, memoryStore: memoryStore) {
            return command
        }

        if let command = parseOpenFolderCreateFolderThenOpenApp(raw: raw, lower: lower, memoryStore: memoryStore) {
            return command
        }

        if let command = parseGenericSequentialOpenCommands(raw: raw, lower: lower, memoryStore: memoryStore) {
            return command
        }

        return nil
    }

    // MARK: - Compound patterns

    private func parseOpenWebsiteAndSearch(
        raw: String,
        lower: String
    ) -> CompoundParsedCommand? {
        let patterns: [(prefix: String, site: String)] = [
            ("abre youtube y busca ", "youtube"),
            ("abre google y busca ", "google"),
            ("abre github y busca ", "github"),

            ("abre youtube y luego busca ", "youtube"),
            ("abre google y luego busca ", "google"),
            ("abre github y luego busca ", "github"),

            ("abrir youtube y busca ", "youtube"),
            ("abrir google y busca ", "google"),
            ("abrir github y busca ", "github")
        ]

        for item in patterns {
            if lower.hasPrefix(item.prefix) {
                let query = String(raw.dropFirst(item.prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !query.isEmpty else { return nil }

                return .single(.searchInsideWebsite(site: item.site, query: query))
            }
        }

        return nil
    }

    private func parseOpenFolderAndCreateFolder(
        raw: String,
        lower: String,
        memoryStore: MemoryStore
    ) -> CompoundParsedCommand? {
        let separators = [
            " y crea una carpeta llamada ",
            " y crear una carpeta llamada ",
            " y haz una carpeta llamada ",
            " y luego crea una carpeta llamada ",
            " y luego crear una carpeta llamada "
        ]

        for separator in separators {
            if let range = lower.range(of: separator) {
                let firstPart = String(raw[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let secondPart = String(raw[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

                guard let folderAction = resolveOpenFolderAction(from: firstPart, memoryStore: memoryStore),
                      !secondPart.isEmpty else {
                    return nil
                }

                let createAction = AssistantAction.createFolder(
                    basePath: extractFolderPath(from: folderAction),
                    folderName: secondPart
                )

                return .sequence([folderAction, createAction])
            }
        }

        return nil
    }

    private func parseOpenFolderAndOpenApp(
        raw: String,
        lower: String,
        memoryStore: MemoryStore
    ) -> CompoundParsedCommand? {
        let separators = [
            " y luego abre ",
            " y abre ",
            " luego abre "
        ]

        for separator in separators {
            if let range = lower.range(of: separator) {
                let firstPart = String(raw[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let secondPart = String(raw[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

                guard let folderAction = resolveOpenFolderAction(from: firstPart, memoryStore: memoryStore),
                      !secondPart.isEmpty else {
                    continue
                }

                if NameNormalizer.normalizeWebsite(secondPart) != nil {
                    continue
                }

                let appAction = AssistantAction.openApp(name: NameNormalizer.normalizeApp(secondPart))
                return .sequence([folderAction, appAction])
            }
        }

        return nil
    }

    private func parseOpenAppAndOpenWebsite(
        raw: String,
        lower: String
    ) -> CompoundParsedCommand? {
        let separators = [
            " y luego abre ",
            " y abre ",
            " luego abre "
        ]

        for separator in separators {
            if let range = lower.range(of: separator) {
                let firstPart = String(raw[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let secondPart = String(raw[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

                guard let appAction = resolveOpenAppAction(from: firstPart),
                      let url = NameNormalizer.normalizeWebsite(secondPart) else {
                    continue
                }

                let siteAction = AssistantAction.openWebsite(url: url)
                return .sequence([appAction, siteAction])
            }
        }

        return nil
    }

    private func parseOpenAppAndQuitApp(
        raw: String,
        lower: String
    ) -> CompoundParsedCommand? {
        let separators = [
            " y luego cierra ",
            " y cierra ",
            " luego cierra "
        ]

        for separator in separators {
            if let range = lower.range(of: separator) {
                let firstPart = String(raw[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let secondPart = String(raw[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

                guard let firstAction = resolveOpenAppAction(from: firstPart),
                      !secondPart.isEmpty else {
                    continue
                }

                let quitAction = AssistantAction.quitApp(name: NameNormalizer.normalizeApp(secondPart))
                return .sequence([firstAction, quitAction])
            }
        }

        return nil
    }

    private func parseOpenFolderAndSearchGoogle(
        raw: String,
        lower: String,
        memoryStore: MemoryStore
    ) -> CompoundParsedCommand? {
        let separators = [
            " y luego busca ",
            " y busca ",
            " luego busca "
        ]

        for separator in separators {
            if let range = lower.range(of: separator) {
                let firstPart = String(raw[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                var secondPart = String(raw[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

                guard let folderAction = resolveOpenFolderAction(from: firstPart, memoryStore: memoryStore),
                      !secondPart.isEmpty else {
                    continue
                }

                secondPart = secondPart.replacingOccurrences(
                    of: " en google",
                    with: "",
                    options: .caseInsensitive
                ).trimmingCharacters(in: .whitespacesAndNewlines)

                guard !secondPart.isEmpty else { continue }

                let searchAction = AssistantAction.searchGoogle(query: secondPart)
                return .sequence([folderAction, searchAction])
            }
        }

        return nil
    }

    private func parseOpenFolderCreateFolderThenOpenApp(
        raw: String,
        lower: String,
        memoryStore: MemoryStore
    ) -> CompoundParsedCommand? {
        guard let createRange = lower.range(of: " y crea una carpeta llamada ")
                ?? lower.range(of: " y luego crea una carpeta llamada ")
                ?? lower.range(of: " y crear una carpeta llamada ")
                ?? lower.range(of: " y haz una carpeta llamada ") else {
            return nil
        }

        let firstPart = String(raw[..<createRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let remaining = String(raw[createRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        let remainingLower = remaining.lowercased()

        guard let thenRange = remainingLower.range(of: " luego abre ")
                ?? remainingLower.range(of: " y luego abre ")
                ?? remainingLower.range(of: " y abre ") else {
            return nil
        }

        let folderName = String(remaining[..<thenRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let lastPart = String(remaining[thenRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

        guard let folderAction = resolveOpenFolderAction(from: firstPart, memoryStore: memoryStore),
              !folderName.isEmpty,
              !lastPart.isEmpty else {
            return nil
        }

        let createAction = AssistantAction.createFolder(
            basePath: extractFolderPath(from: folderAction),
            folderName: folderName
        )

        let openAppAction = AssistantAction.openApp(name: NameNormalizer.normalizeApp(lastPart))

        return .sequence([folderAction, createAction, openAppAction])
    }

    private func parseGenericSequentialOpenCommands(
        raw: String,
        lower: String,
        memoryStore: MemoryStore
    ) -> CompoundParsedCommand? {
        let normalized = lower
            .replacingOccurrences(of: " luego ", with: " | ")
            .replacingOccurrences(of: " después ", with: " | ")
            .replacingOccurrences(of: " despues ", with: " | ")

        let parts = normalized.split(separator: "|").map {
            String($0).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard parts.count >= 2 else { return nil }

        var actions: [AssistantAction] = []

        for part in parts {
            if let folderAction = resolveOpenFolderAction(from: part, memoryStore: memoryStore) {
                actions.append(folderAction)
                continue
            }

            if let appAction = resolveOpenAppAction(from: part) {
                actions.append(appAction)
                continue
            }

            if let websiteAction = resolveOpenWebsiteAction(from: part) {
                actions.append(websiteAction)
                continue
            }

            return nil
        }

        return actions.isEmpty ? nil : .sequence(actions)
    }

    // MARK: - Resolvers

    private func resolveOpenFolderAction(from text: String, memoryStore: MemoryStore) -> AssistantAction? {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        let prefixes = [
            "abre la carpeta ",
            "abre carpeta ",
            "abrir carpeta ",
            "open folder ",
            "abre ",
            "abrir ",
            "open "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let value = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let site = NameNormalizer.normalizeWebsite(value) {
                    _ = site
                    return nil
                }

                if let folderPath = memoryStore.folderPath(for: value) {
                    return .openFolder(path: folderPath)
                }

                let normalized = PathNormalizer.normalizeFolderPath(value)
                return .openFolder(path: normalized)
            }
        }

        return nil
    }

    private func resolveOpenAppAction(from text: String) -> AssistantAction? {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        let prefixes = [
            "abre ",
            "abrir ",
            "open ",
            "inicia ",
            "ejecuta ",
            "lanza "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let value = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !value.isEmpty else { return nil }

                if NameNormalizer.normalizeWebsite(value) != nil {
                    return nil
                }

                return .openApp(name: NameNormalizer.normalizeApp(value))
            }
        }

        return nil
    }

    private func resolveOpenWebsiteAction(from text: String) -> AssistantAction? {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        let prefixes = [
            "abre ",
            "abrir ",
            "open "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let value = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard let url = NameNormalizer.normalizeWebsite(value) else { return nil }
                return .openWebsite(url: url)
            }
        }

        return nil
    }

    private func extractFolderPath(from action: AssistantAction) -> String {
        switch action {
        case .openFolder(let path):
            return path
        default:
            return ""
        }
    }
}
