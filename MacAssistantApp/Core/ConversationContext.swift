//
//  ConversationContext.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

enum ConversationEntityKind: String, Codable {
    case app
    case folder
    case website
    case search
    case workflow
    case file
    case unknown
}

struct ConversationContext {
    var lastOpenedFolderPath: String?
    var lastOpenedAppName: String?
    var lastOpenedWebsiteURL: String?
    var lastWorkflowName: String?
    var lastSearchQuery: String?
    var lastTopic: String?

    var lastEntityKind: ConversationEntityKind = .unknown
    var lastEntityValue: String?
    var lastActionSummary: String?
}
