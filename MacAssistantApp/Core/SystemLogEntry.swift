//
//  SystemLogEntry.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct SystemLogEntry: Identifiable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}
