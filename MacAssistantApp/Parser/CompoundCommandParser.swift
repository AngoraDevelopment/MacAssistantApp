//
//  CompoundCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct CompoundCommandParser {
    func parse(_ input: String) -> AssistantAction? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        let patterns: [(prefix: String, site: String)] = [
            ("abre youtube y busca ", "youtube"),
            ("open youtube and search ", "youtube"),

            ("abre google y busca ", "google"),
            ("open google and search ", "google"),

            ("abre github y busca ", "github"),
            ("open github and search ", "github")
        ]

        for item in patterns {
            if lower.hasPrefix(item.prefix) {
                let query = String(raw.dropFirst(item.prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !query.isEmpty else { return nil }

                return .searchInsideWebsite(site: item.site, query: query)
            }
        }

        return nil
    }
}
