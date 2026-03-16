//
//  WorkflowExecutionService.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

@MainActor
final class WorkflowExecutionService {
    private let workflowStore: WorkflowStore

    init(workflowStore: WorkflowStore) {
        self.workflowStore = workflowStore
    }

    func listWorkflows() -> AssistantExecutionResult {
        let workflows = workflowStore.all()

        guard !workflows.isEmpty else {
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "No hay workflows guardados",
                userMessage: "Ahora mismo no hay workflows guardados."
            )
        }

        let lines = workflows.map { "- \($0.name) (\($0.commands.count) comandos)" }

        return AssistantExecutionResult(
            success: true,
            technicalMessage: lines.joined(separator: "\n"),
            userMessage: "Estos son los workflows guardados:\n" + lines.joined(separator: "\n")
        )
    }

    func createWorkflow(name: String, commands: [String]) -> AssistantExecutionResult {
        workflowStore.addWorkflow(name: name, commands: commands)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Workflow guardado → \(name)",
            userMessage: "Listo, guardé el workflow '\(name)'."
        )
    }

    func deleteWorkflow(name: String) -> AssistantExecutionResult {
        workflowStore.deleteWorkflow(named: name)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Workflow eliminado → \(name)",
            userMessage: "Listo, borré el workflow '\(name)'."
        )
    }
}
