//
//  WorkflowPatternSuggestion.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct WorkflowPatternSuggestion: Identifiable, Equatable {
    let id: UUID
    let suggestedName: String
    let commands: [String]

    init(
        id: UUID = UUID(),
        suggestedName: String,
        commands: [String]
    ) {
        self.id = id
        self.suggestedName = suggestedName
        self.commands = commands
    }
}
