//
//  PlannedAction.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct PlannedAction: Identifiable, Equatable {
    let id: UUID
    let action: AssistantAction
    let sourceText: String

    init(id: UUID = UUID(), action: AssistantAction, sourceText: String) {
        self.id = id
        self.action = action
        self.sourceText = sourceText
    }
}
