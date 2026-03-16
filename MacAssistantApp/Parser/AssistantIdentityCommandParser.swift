//
//  AssistantIdentityCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

enum AssistantIdentityCommand {
    case setName(String)
    case askName
}

struct AssistantIdentityCommandParser {
    func parse(_ input: String) -> AssistantIdentityCommand? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        let prefixes = [
            "tu nombre será ",
            "tu nombre sera ",
            "te llamarás ",
            "te llamaras ",
            "quiero llamarte ",
            "vas a llamarte ",
            "tu nombre es "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let name = String(raw.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return nil }
                return .setName(name)
            }
        }

        let askPhrases = [
            "cómo te llamas",
            "como te llamas",
            "cuál es tu nombre",
            "cual es tu nombre",
            "tienes nombre"
        ]

        if askPhrases.contains(where: { lower.contains($0) }) {
            return .askName
        }

        return nil
    }
}
