//
//  WebCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct WebCommandParser: TraceableAssistantActionParsing {
    let memoryStore: MemoryStore
    let parserName: String = "WebCommandParser"

    func parse(_ input: String) -> AssistantAction? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        if let action = parseDirectURL(raw: raw) {
            return action
        }

        if let action = parseKnownWebsite(raw: raw, lower: lower) {
            return action
        }

        if let action = parseWebsiteAlias(raw: raw, lower: lower) {
            return action
        }

        if let action = parseGoogleSearch(raw: raw, lower: lower) {
            return action
        }

        return nil
    }

    private func parseDirectURL(raw: String) -> AssistantAction? {
        guard raw.hasPrefix("http://") || raw.hasPrefix("https://") else {
            return nil
        }

        guard let url = URL(string: raw) else { return nil }
        return .openWebsite(url: url)
    }

    private func parseKnownWebsite(raw: String, lower: String) -> AssistantAction? {
        let mapping: [String: String] = [
            "abre github": "https://github.com",
            "abrir github": "https://github.com",
            "open github": "https://github.com",
            "abre youtube": "https://youtube.com",
            "abrir youtube": "https://youtube.com",
            "open youtube": "https://youtube.com",
            "abre google": "https://google.com",
            "abrir google": "https://google.com",
            "open google": "https://google.com"
        ]

        guard let urlString = mapping[lower],
              let url = URL(string: urlString) else {
            return nil
        }

        return .openWebsite(url: url)
    }

    private func parseWebsiteAlias(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "abre ",
            "abrir ",
            "open "
        ]

        for prefix in prefixes where lower.hasPrefix(prefix) {
            let value = String(raw.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !value.isEmpty else { return nil }

            if let websiteAlias = memoryStore.websiteURL(for: value),
               let url = URL(string: websiteAlias) {
                return .openWebsite(url: url)
            }
        }

        return nil
    }

    private func parseGoogleSearch(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "busca ",
            "buscar ",
            "search "
        ]

        for prefix in prefixes where lower.hasPrefix(prefix) {
            let value = String(raw.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !value.isEmpty else { return nil }

            let cleanedQuery = value
                .replacingOccurrences(of: " en google", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: " on google", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !cleanedQuery.isEmpty else { return nil }
            return .searchGoogle(query: cleanedQuery)
        }

        return nil
    }
}
