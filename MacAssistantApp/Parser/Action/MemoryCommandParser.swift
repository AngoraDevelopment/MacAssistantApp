//
//  MemoryCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation

struct MemoryCommandParser: TraceableAssistantActionParsing {
    let memoryStore: MemoryStore
    let parserName: String = "MemoryCommandParser"

    func parse(_ input: String) -> AssistantAction? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        if lower == "qué recuerdas" || lower == "que recuerdas" {
            return .listMemory
        }

        if lower == "lista carpetas" || lower == "listar carpetas" {
            return .listFolderAliases
        }

        if lower == "lista apps" || lower == "listar apps" {
            return .listAppAliases
        }

        if lower == "lista sitios" || lower == "listar sitios" {
            return .listWebsiteAliases
        }

        let forgetPrefixes = [
            "olvida ",
            "borra alias ",
            "elimina alias "
        ]

        for prefix in forgetPrefixes where lower.hasPrefix(prefix) {
            let alias = String(raw.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !alias.isEmpty else { return nil }

            if memoryStore.folderPath(for: alias) != nil {
                return .forgetFolderAlias(alias: alias)
            }

            if memoryStore.appName(for: alias) != nil {
                return .forgetAppAlias(alias: alias)
            }

            if memoryStore.websiteURL(for: alias) != nil {
                return .forgetWebsiteAlias(alias: alias)
            }

            return nil
        }

        if lower.hasPrefix("recuerda que "),
           let range = raw.range(of: "=") {
            let left = String(raw[..<range.lowerBound])
            let right = String(raw[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let alias = left
                .replacingOccurrences(of: "recuerda que ", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !alias.isEmpty, !right.isEmpty else { return nil }

            if right.hasPrefix("http://") || right.hasPrefix("https://") {
                return .rememberWebsiteAlias(alias: alias, url: right)
            }

            if right.hasPrefix("/") || right.hasPrefix("~") {
                return .rememberFolderAlias(alias: alias, path: right)
            }

            return .rememberAppAlias(alias: alias, appName: right)
        }

        return nil
    }
}
