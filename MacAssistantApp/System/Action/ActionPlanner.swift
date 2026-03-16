//
//  ActionPlanner.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

@MainActor
final class ActionPlanner: ActionPlanning {
    private let parser: CommandParser
    private let memoryStore: MemoryStore

    init(
        parser: CommandParser,
        memoryStore: MemoryStore
    ) {
        self.parser = parser
        self.memoryStore = memoryStore
    }

    func buildPlan(from input: String) -> ActionPlan? {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }

        if let plan = buildWebsiteSearchPlan(from: cleaned) {
            return plan
        }

        if let plan = buildFolderCreatePlan(from: cleaned) {
            return plan
        }

        if let plan = buildSequentialPlan(from: cleaned) {
            return plan
        }

        let action = parser.parse(cleaned)
        guard action != .unknown else { return nil }

        return ActionPlan(
            originalInput: cleaned,
            steps: [
                PlannedAction(action: action, sourceText: cleaned)
            ]
        )
    }

    // MARK: - Specialized planners

    private func buildWebsiteSearchPlan(from input: String) -> ActionPlan? {
        let raw = input
        let lower = input.lowercased()

        let patterns: [(prefix: String, site: String)] = [
            ("abre youtube y busca ", "youtube"),
            ("abre youtube y luego busca ", "youtube"),
            ("abre google y busca ", "google"),
            ("abre google y luego busca ", "google"),
            ("abre github y busca ", "github"),
            ("abre github y luego busca ", "github")
        ]

        for item in patterns {
            if lower.hasPrefix(item.prefix) {
                let query = String(raw.dropFirst(item.prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !query.isEmpty else { return nil }

                let action = AssistantAction.searchInsideWebsite(site: item.site, query: query)

                return ActionPlan(
                    originalInput: raw,
                    steps: [
                        PlannedAction(action: action, sourceText: raw)
                    ]
                )
            }
        }

        return nil
    }

    private func buildFolderCreatePlan(from input: String) -> ActionPlan? {
        let raw = input
        let lower = input.lowercased()

        let separators = [
            " y crea una carpeta llamada ",
            " y luego crea una carpeta llamada ",
            " y haz una carpeta llamada "
        ]

        for separator in separators {
            guard let range = lower.range(of: separator) else { continue }

            let firstPart = String(raw[..<range.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let secondPart = String(raw[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !secondPart.isEmpty else { return nil }

            let firstAction = parser.parse(firstPart)
            guard case .openFolder(let basePath) = firstAction else { return nil }

            let createAction = AssistantAction.createFolder(
                basePath: basePath,
                folderName: secondPart
            )

            return ActionPlan(
                originalInput: raw,
                steps: [
                    PlannedAction(action: firstAction, sourceText: firstPart),
                    PlannedAction(action: createAction, sourceText: secondPart)
                ]
            )
        }

        return nil
    }

    private func buildSequentialPlan(from input: String) -> ActionPlan? {
        let raw = input

        let normalized = raw
            .replacingOccurrences(of: " y luego ", with: " | ", options: .caseInsensitive)
            .replacingOccurrences(of: " luego ", with: " | ", options: .caseInsensitive)
            .replacingOccurrences(of: " después ", with: " | ", options: .caseInsensitive)
            .replacingOccurrences(of: " despues ", with: " | ", options: .caseInsensitive)
            .replacingOccurrences(of: " entonces ", with: " | ", options: .caseInsensitive)

        let parts = normalized
            .split(separator: "|")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard parts.count >= 2 else { return nil }

        var steps: [PlannedAction] = []

        for part in parts {
            let action = parser.parse(part)
            guard action != .unknown else { return nil }
            steps.append(PlannedAction(action: action, sourceText: part))
        }

        return ActionPlan(originalInput: raw, steps: steps)
    }
}
