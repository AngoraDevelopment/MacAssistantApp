//
//  AssistantWorkflow.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/10/26.
//

import Foundation

struct AssistantWorkflow: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var commands: [String]

    init(id: UUID = UUID(), name: String, commands: [String]) {
        self.id = id
        self.name = name
        self.commands = commands
    }
}
