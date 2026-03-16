//
//  MemoryCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation

struct MemoryCommandParser {
    func parse(_ input: String) -> AssistantAction? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        if let action = parseListMemory(lower: lower) {
            return action
        }

        if let action = parseRemember(raw: raw, lower: lower) {
            return action
        }

        if let action = parseForget(raw: raw, lower: lower) {
            return action
        }

        if let action = parseClearMemory(lower: lower) {
            return action
        }

        return nil
    }

    private func parseRemember(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "recuerda que ",
            "remember that ",
            "recuerda "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let remainder = String(raw.dropFirst(prefix.count))

                if let eqIndex = remainder.firstIndex(of: "=") {
                    let alias = String(remainder[..<eqIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = String(remainder[remainder.index(after: eqIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !alias.isEmpty, !value.isEmpty else { return nil }

                    if value.hasPrefix("http://") || value.hasPrefix("https://") {
                        return .rememberWebsiteAlias(alias: alias, url: value)
                    }

                    if value.contains("/") || value.hasPrefix("~") {
                        return .rememberFolderAlias(
                            alias: alias,
                            path: NSString(string: value).expandingTildeInPath
                        )
                    }

                    return .rememberAppAlias(alias: alias, appName: value)
                }
            }
        }

        return nil
    }

    private func parseForget(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "olvida ",
            "forget "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let alias = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !alias.isEmpty else { return nil }

                return .forgetFolderAlias(alias: alias)
            }
        }

        return nil
    }

    private func parseListMemory(lower: String) -> AssistantAction? {
        let allMemoryPhrases = [
            "que recuerdas",
            "qué recuerdas",
            "muestra mi memoria",
            "muestra mis aliases",
            "lista mi memoria",
            "lista mis aliases",
            "show memory",
            "list memory"
        ]

        if allMemoryPhrases.contains(where: { lower.contains($0) }) {
            return .listMemory
        }

        let folderPhrases = [
            "lista mis carpetas",
            "lista mis carpetas guardadas",
            "muestra mis carpetas",
            "show folder aliases"
        ]

        if folderPhrases.contains(where: { lower.contains($0) }) {
            return .listFolderAliases
        }

        let appPhrases = [
            "lista mis apps",
            "lista mis apps guardadas",
            "muestra mis apps",
            "show app aliases"
        ]

        if appPhrases.contains(where: { lower.contains($0) }) {
            return .listAppAliases
        }

        let websitePhrases = [
            "lista mis sitios",
            "lista mis sitios guardados",
            "muestra mis sitios",
            "show website aliases"
        ]

        if websitePhrases.contains(where: { lower.contains($0) }) {
            return .listWebsiteAliases
        }

        return nil
    }

    private func parseClearMemory(lower: String) -> AssistantAction? {
        let phrases = [
            "borra toda la memoria",
            "elimina toda la memoria",
            "limpia la memoria",
            "clear memory"
        ]

        if phrases.contains(where: { lower.contains($0) }) {
            return .clearMemory
        }

        return nil
    }
}
