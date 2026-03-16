//
//  FileCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct FileCommandParser: TraceableAssistantActionParsing {
    let parserName: String = "FileCommandParser"

    func parse(_ input: String) -> AssistantAction? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        if let action = parseOpenFile(raw: raw, lower: lower) {
            return action
        }

        if let action = parseFindFile(raw: raw, lower: lower) {
            return action
        }

        return nil
    }

    private func parseOpenFile(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "abre el archivo ",
            "abrir el archivo ",
            "open file ",
            "abre archivo ",
            "abre "
        ]

        for prefix in prefixes where lower.hasPrefix(prefix) {
            let value = String(raw.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard looksLikeFileQuery(value) else { continue }
            return .findFile(query: value)
        }

        return nil
    }

    private func parseFindFile(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "busca archivo ",
            "buscar archivo ",
            "encuentra archivo ",
            "busca el archivo ",
            "encuentra el archivo ",
            "busca ",
            "encuentra "
        ]

        for prefix in prefixes where lower.hasPrefix(prefix) {
            let value = String(raw.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard looksLikeFileQuery(value) else { continue }
            return .findFile(query: value)
        }

        return nil
    }

    private func looksLikeFileQuery(_ value: String) -> Bool {
        let lower = value.lowercased()

        if lower.contains(".") { return true }

        let fileHints = [
            "png", "jpg", "jpeg", "gif", "webp",
            "json", "txt", "pdf", "swift", "cs", "cpp",
            "zip", "rar", "mp3", "wav", "mp4", "mov"
        ]

        return fileHints.contains { lower.contains($0) }
    }
}
