//
//  ActionHistoryEntry.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct ActionHistoryEntry: Identifiable, Equatable, Codable {
    let id: UUID
    let command: String
    let normalizedCommand: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        command: String,
        normalizedCommand: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.command = command
        self.normalizedCommand = normalizedCommand
        self.createdAt = createdAt
    }
}
