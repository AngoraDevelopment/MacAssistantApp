//
//  AssistantWakeParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct AssistantWakeResult {
    let wasInvoked: Bool
    let cleanedInput: String
}

struct AssistantWakeParser {
    let assistantName: String?

    func parse(_ input: String) -> AssistantWakeResult {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let assistantName,
              !assistantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return AssistantWakeResult(
                wasInvoked: false,
                cleanedInput: raw
            )
        }

        let lowerInput = raw.lowercased()
        let lowerName = assistantName.lowercased()

        let prefixes = [
            "\(lowerName),",
            "\(lowerName):",
            "\(lowerName) ",
            "\(lowerName)?",
            "\(lowerName)."
        ]

        for prefix in prefixes {
            if lowerInput.hasPrefix(prefix) {
                let cleaned = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                return AssistantWakeResult(
                    wasInvoked: true,
                    cleanedInput: cleaned
                )
            }
        }

        if lowerInput == lowerName {
            return AssistantWakeResult(
                wasInvoked: true,
                cleanedInput: ""
            )
        }

        return AssistantWakeResult(
            wasInvoked: false,
            cleanedInput: raw
        )
    }
}
