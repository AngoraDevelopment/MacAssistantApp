//
//  PendingConfirmation.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/10/26.
//

import Foundation

struct PendingConfirmation {
    let action: AssistantAction
    let createdAt: Date
    let reason: String
    let workflowContext: PendingWorkflowExecution?
}
