//
//  ConversationalCommandCleaner.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct ConversationalCommandCleaner {
    func clean(_ input: String, assistantName: String?) -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)

        let removablePrefixes = [
            "hola ",
            "hey ",
            "buenas ",
            "por favor ",
            "oye "
        ]

        var didChange = true

        while didChange {
            didChange = false

            for prefix in removablePrefixes {
                if text.lowercased().hasPrefix(prefix) {
                    text = String(text.dropFirst(prefix.count))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    didChange = true
                }
            }
        }

        if let assistantName {
            let wake = AssistantWakeParser(assistantName: assistantName).parse(text)
            text = wake.cleanedInput
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
