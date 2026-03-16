//
//  ConversationContextStore.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation
internal import Combine

@MainActor
final class ConversationContextStore: ObservableObject {
    @Published private(set) var context = ConversationContext()

    func setLastOpenedFolderPath(_ path: String) {
        context.lastOpenedFolderPath = path
        context.lastEntityKind = .folder
        context.lastEntityValue = path
    }
    
    func setLastFilePath(_ path: String) {
        context.lastTopic = "file"
        context.lastEntityKind = .file
        context.lastEntityValue = path
    }

    func setLastFileQuery(_ query: String) {
        context.lastTopic = "file"
        context.lastEntityKind = .file
        context.lastEntityValue = query
    }
    
    func setLastOpenedAppName(_ name: String) {
        context.lastOpenedAppName = name
        context.lastEntityKind = .app
        context.lastEntityValue = name
    }

    func setLastOpenedWebsiteURL(_ url: String) {
        context.lastOpenedWebsiteURL = url
        context.lastEntityKind = .website
        context.lastEntityValue = url
    }

    func setLastWorkflowName(_ name: String) {
        context.lastWorkflowName = name
        context.lastEntityKind = .workflow
        context.lastEntityValue = name
    }

    func setLastSearchQuery(_ query: String) {
        context.lastSearchQuery = query
        context.lastEntityKind = .search
        context.lastEntityValue = query
    }

    func setLastTopic(_ topic: String) {
        context.lastTopic = topic
    }

    func setLastActionSummary(_ summary: String) {
        context.lastActionSummary = summary
    }

    func clear() {
        context = ConversationContext()
    }
}
