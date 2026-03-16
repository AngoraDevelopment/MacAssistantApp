//
//  AssistantKnowledgeParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

enum AssistantKnowledgeIntent {
    case capabilities
    case memoryHelp
    case workflowHelp
    case commandsHelp
    case unknown
}

struct AssistantKnowledgeParser {
    func parse(_ input: String) -> AssistantKnowledgeIntent {
        let lower = input.lowercased()

        if lower.contains("qué puedes hacer") || lower.contains("que puedes hacer") {
            return .capabilities
        }

        if lower.contains("cómo guardo un alias") || lower.contains("como guardo un alias") {
            return .memoryHelp
        }

        if lower.contains("cómo creo un workflow") || lower.contains("como creo un workflow") {
            return .workflowHelp
        }

        if lower.contains("qué comandos entiendes") || lower.contains("que comandos entiendes") {
            return .commandsHelp
        }

        return .unknown
    }
}
