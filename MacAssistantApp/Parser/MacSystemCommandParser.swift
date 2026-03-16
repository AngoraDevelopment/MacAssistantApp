//
//  SystemCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct MacSystemCommandParser: TraceableAssistantActionParsing {

    let parserName: String = "MacSystemCommandParser"

    func parse(_ input: String) -> AssistantAction? {
        let lower = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if lower == "apaga la mac" || lower == "apagar la mac" {
            return .shutdownMac
        }

        return nil
    }

}
