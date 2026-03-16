//
//  AssistantSuggestion.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct AssistantSuggestion: Identifiable, Equatable {
    let id: UUID
    let title: String
    let command: String
    let category: SuggestionCategory

    init(
        id: UUID = UUID(),
        title: String,
        command: String,
        category: SuggestionCategory
    ) {
        self.id = id
        self.title = title
        self.command = command
        self.category = category
    }
}

enum SuggestionCategory: String, Equatable {
    case folder
    case app
    case website
    case search
    case workflow
    case memory
    case general
}
