//
//  AssistantCoordinatorDependencies.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct AssistantCoordinatorDependencies {
    let parser: CommandParser
    let executor: SystemActionExecutor
    let validator: AssistantActionValidator

    let memoryStore: MemoryStore
    let workflowStore: WorkflowStore
    let identityStore: AssistantIdentityStore
    let conversationContextStore: ConversationContextStore
    let installedAppsIndex: InstalledAppsIndex
    let userFilesIndex: UserFilesIndex
}
