//
//  ActionPlanExecutor.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

@MainActor
final class ActionPlanExecutor {
    private let validator: AssistantActionValidator
    private let executor: SystemActionExecutor

    init(
        validator: AssistantActionValidator,
        executor: SystemActionExecutor
    ) {
        self.validator = validator
        self.executor = executor
    }

    func executePlan(
        _ plan: ActionPlan,
        naturalize: (String) -> String,
        updateContext: (AssistantAction) -> Void,
        refreshSuggestions: (AssistantAction, AssistantExecutionResult) -> [AssistantSuggestion]
    ) -> ActionPlanExecutionResult {
        var result = ActionPlanExecutionResult()
        var executedAny = false

        for step in plan.steps {
            let action = step.action

            result.systemLogs.append("Plan step → \(String(describing: action))")

            switch validator.validate(action) {
            case .invalid(let message):
                result.systemLogs.append("Validación fallida → \(message)")
                result.assistantMessages.append(message)
                result.statusMessage = message
                result.didExecuteAction = executedAny
                return result

            case .warning(let message):
                result.pendingConfirmation = PendingConfirmation(
                    action: action,
                    createdAt: Date(),
                    reason: message,
                    workflowContext: nil
                )
                result.assistantMessages.append("\(message) Escribe CONFIRMAR para continuar o CANCELAR para abortar.")
                result.statusMessage = "Esperando confirmación"
                result.didExecuteAction = executedAny
                return result

            case .valid:
                break
            }

            if action.requiresConfirmation {
                result.pendingConfirmation = PendingConfirmation(
                    action: action,
                    createdAt: Date(),
                    reason: action.confirmationMessage,
                    workflowContext: nil
                )
                result.assistantMessages.append(action.confirmationMessage)
                result.statusMessage = "Esperando confirmación"
                result.didExecuteAction = executedAny
                return result
            }

            let execution = executor.execute(action)

            if execution.success {
                updateContext(action)
                executedAny = true
                result.executedCommandsForPatternDetection.append(step.sourceText)
            }

            result.systemLogs.append(execution.technicalMessage)
            result.assistantMessages.append(naturalize(execution.userMessage))
            result.statusMessage = execution.userMessage
            result.suggestions = refreshSuggestions(action, execution)

            if !execution.success {
                result.didExecuteAction = executedAny
                return result
            }
        }

        result.didExecuteAction = executedAny
        return result
    }
}
