//
//  AppCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct AppCommandParser: TraceableAssistantActionParsing {
    let memoryStore: MemoryStore
    let parserName: String = "AppCommandParser"

    func parse(_ input: String) -> AssistantAction? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        if let action = parseOpenApp(raw: raw, lower: lower) {
            return action
        }

        if let action = parseQuitApp(raw: raw, lower: lower) {
            return action
        }

        return nil
    }

    private func parseOpenApp(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "abre ",
            "abrir ",
            "open ",
            "inicia ",
            "lanza ",
            "ejecuta "
        ]

        for prefix in prefixes where lower.hasPrefix(prefix) {
            let value = String(raw.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !value.isEmpty else { return nil }

            if memoryStore.folderPath(for: value) != nil { return nil }
            if memoryStore.websiteURL(for: value) != nil { return nil }

            if let appAlias = memoryStore.appName(for: value) {
                return .openApp(name: appAlias)
            }

            if value.hasPrefix("http://") || value.hasPrefix("https://") { return nil }
            if value.contains("/") || value.hasPrefix("~") { return nil }

            return .openApp(name: value)
        }

        return nil
    }

    private func parseQuitApp(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "cierra ",
            "cerrar ",
            "close ",
            "quit ",
            "termina "
        ]

        for prefix in prefixes where lower.hasPrefix(prefix) {
            let value = String(raw.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !value.isEmpty else { return nil }

            if let appAlias = memoryStore.appName(for: value) {
                return .quitApp(name: appAlias)
            }

            return .quitApp(name: value)
        }

        return nil
    }
}
