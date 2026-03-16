//
//  ActionPlanExecutionResult.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct ActionPlanExecutionResult {
    var assistantMessages: [String] = []
    var systemLogs: [String] = []
    var statusMessage: String = "Listo"

    var pendingConfirmation: PendingConfirmation?
    var suggestions: [AssistantSuggestion] = []

    var executedCommandsForPatternDetection: [String] = []
    var didExecuteAction: Bool = false
}
