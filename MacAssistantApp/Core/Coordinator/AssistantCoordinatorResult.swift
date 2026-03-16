//
//  AssistantCoordinatorResult.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct AssistantCoordinatorResult {
    var assistantMessages: [String] = []
    var systemLogs: [String] = []
    var statusMessage: String = "Listo"

    var pendingConfirmation: PendingConfirmation?
    var pendingWorkflowExecution: PendingWorkflowExecution?
    var pendingWorkflowSuggestion: WorkflowPatternSuggestion?

    var suggestions: [AssistantSuggestion] = []

    var didExecuteAction: Bool = false
    var executedCommandsForPatternDetection: [String] = []
}
