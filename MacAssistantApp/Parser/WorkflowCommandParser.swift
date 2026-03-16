//
//  WorkflowCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/10/26.
//

import Foundation
internal import Combine

struct WorkflowCommandParser {
    func parse(_ input: String) -> AssistantAction? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        if let action = parseRunWorkflow(raw: raw, lower: lower) {
            return action
        }

        if let action = parseListWorkflows(lower: lower) {
            return action
        }

        if let action = parseDeleteWorkflow(raw: raw, lower: lower) {
            return action
        }

        if let action = parseCreateWorkflow(raw: raw, lower: lower) {
            return action
        }

        return nil
    }

    private func parseRunWorkflow(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "ejecuta workflow ",
            "ejecuta ",
            "run workflow ",
            "run ",
            "abrir entorno "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let name = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !name.isEmpty else { return nil }
                return .runWorkflow(name: name)
            }
        }

        return nil
    }

    private func parseListWorkflows(lower: String) -> AssistantAction? {
        let phrases = [
            "lista workflows",
            "muestra workflows",
            "que workflows hay",
            "qué workflows hay",
            "list workflows",
            "entornos"
        ]

        if phrases.contains(where: { lower.contains($0) }) {
            return .listWorkflows
        }

        return nil
    }

    private func parseDeleteWorkflow(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "borra workflow ",
            "elimina workflow ",
            "delete workflow ",
            "borrar entorno ",
            "borra entorno "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let name = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !name.isEmpty else { return nil }
                return .deleteWorkflow(name: name)
            }
        }

        return nil
    }

    private func parseCreateWorkflow(raw: String, lower: String) -> AssistantAction? {
        let prefixes = [
            "crea workflow ",
            "crear workflow ",
            "create workflow ",
            "crear entorno "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let remainder = String(raw.dropFirst(prefix.count))

                guard let separatorRange = remainder.range(of: ":") else { return nil }

                let name = String(remainder[..<separatorRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let commandsPart = String(remainder[separatorRange.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let commands = commandsPart
                    .split(separator: ";")
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                guard !name.isEmpty, !commands.isEmpty else { return nil }

                return .createWorkflow(name: name, commands: commands)
            }
        }

        return nil
    }
}
