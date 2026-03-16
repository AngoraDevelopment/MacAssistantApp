//
//  AssistantViewModel.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation
import AppKit
internal import Combine

@MainActor
final class AssistantViewModel: ObservableObject {
    @Published var commandText: String = ""
    @Published var statusMessage: String = "Listo"

    @Published var chatMessages: [ChatMessage] = []
    @Published var systemLogs: [SystemLogEntry] = []

    @Published var pendingConfirmation: PendingConfirmation?
    @Published var pendingWorkflowExecution: PendingWorkflowExecution?
    @Published var pendingWorkflowSuggestion: WorkflowPatternSuggestion?

    @Published var suggestions: [AssistantSuggestion] = []

    let memoryStore: MemoryStore
    let workflowStore: WorkflowStore
    let identityStore: AssistantIdentityStore
    let conversationContextStore: ConversationContextStore
    let installedAppsIndex: InstalledAppsIndex
    let userFilesIndex: UserFilesIndex

    private let parser: CommandParser
    private let executor: SystemActionExecutor
    private let validator: AssistantActionValidator
    private let coordinator: AssistantCoordinator

    private var actionHistory: [ActionHistoryEntry] = []

    var assistantDisplayName: String {
        identityStore.assistantName ?? "Assistant"
    }

    init() {
        let memoryStore = MemoryStore()
        let workflowStore = WorkflowStore()
        let identityStore = AssistantIdentityStore()
        let conversationContextStore = ConversationContextStore()
        let installedAppsIndex = InstalledAppsIndex()
        let userFilesIndex = UserFilesIndex()

        installedAppsIndex.rebuild()
        userFilesIndex.rebuild()

        self.memoryStore = memoryStore
        self.workflowStore = workflowStore
        self.identityStore = identityStore
        self.conversationContextStore = conversationContextStore
        self.installedAppsIndex = installedAppsIndex
        self.userFilesIndex = userFilesIndex

        self.parser = CommandParser(
            memoryStore: memoryStore,
            workflowStore: workflowStore
        )

        let appService = AppExecutionService(installedAppsIndex: installedAppsIndex)
        let fileService = FileExecutionService(userFilesIndex: userFilesIndex)
        let folderService = FolderExecutionService()
        let webService = WebExecutionService()
        let memoryService = MemoryExecutionService(memoryStore: memoryStore)
        let workflowService = WorkflowExecutionService(workflowStore: workflowStore)

        self.executor = SystemActionExecutor(
            appService: appService,
            fileService: fileService,
            folderService: folderService,
            webService: webService,
            memoryService: memoryService,
            workflowService: workflowService
        )

        self.validator = AssistantActionValidator(
            memoryStore: memoryStore,
            installedAppsIndex: installedAppsIndex,
            userFilesIndex: userFilesIndex
        )

        let dependencies = AssistantCoordinatorDependencies(
            parser: parser,
            executor: executor,
            validator: validator,
            memoryStore: memoryStore,
            workflowStore: workflowStore,
            identityStore: identityStore,
            conversationContextStore: conversationContextStore,
            installedAppsIndex: installedAppsIndex,
            userFilesIndex: userFilesIndex
        )

        self.coordinator = AssistantCoordinator(dependencies: dependencies)

        if let name = identityStore.assistantName {
            addAssistantMessage("Hola. Soy \(name). Estoy listo para ayudarte.")
        } else {
            addAssistantMessage("Hola. Estoy listo para ayudarte. Si quieres, puedes ponerme nombre una sola vez.")
        }
    }

    // MARK: - Main input

    func runCommand() {
        let originalCommand = commandText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !originalCommand.isEmpty else {
            statusMessage = "Escribe un mensaje primero"
            return
        }

        addUserMessage(originalCommand)

        let result = coordinator.handleInput(
            originalCommand,
            pendingConfirmation: pendingConfirmation,
            pendingWorkflowExecution: pendingWorkflowExecution,
            actionHistory: actionHistory
        )

        applyCoordinatorResult(result)
        commandText = ""
    }

    // MARK: - Apply coordinator result

    private func applyCoordinatorResult(_ result: AssistantCoordinatorResult) {
        for message in result.assistantMessages {
            addAssistantMessage(message)
        }

        for log in result.systemLogs {
            addSystemLog(log)
        }

        statusMessage = result.statusMessage
        pendingConfirmation = result.pendingConfirmation
        pendingWorkflowExecution = result.pendingWorkflowExecution
        pendingWorkflowSuggestion = result.pendingWorkflowSuggestion
        suggestions = result.suggestions

        if !result.executedCommandsForPatternDetection.isEmpty {
            for command in result.executedCommandsForPatternDetection {
                registerExecutedCommandForPatternDetection(command)
            }
        }
    }

    // MARK: - Chat / Logs

    func addUserMessage(_ text: String) {
        chatMessages.append(ChatMessage(role: .user, text: text))
    }

    func addAssistantMessage(_ text: String) {
        chatMessages.append(ChatMessage(role: .assistant, text: text))
    }

    func addSystemLog(_ text: String) {
        systemLogs.append(SystemLogEntry(text: text))
    }

    // MARK: - Suggestions

    func clearSuggestions() {
        suggestions = []
    }

    func runSuggestedCommand(_ command: String) {
        commandText = command
        runCommand()
    }

    // MARK: - Workflow pattern suggestion

    func acceptPendingWorkflowSuggestion() {
        guard let suggestion = pendingWorkflowSuggestion else { return }

        workflowStore.addWorkflow(
            name: suggestion.suggestedName,
            commands: suggestion.commands
        )

        addAssistantMessage("Listo, guardé esa rutina como workflow '\(suggestion.suggestedName)'.")
        addSystemLog("Workflow creado desde sugerencia → \(suggestion.suggestedName)")
        statusMessage = "Workflow guardado"
        pendingWorkflowSuggestion = nil
    }

    func rejectPendingWorkflowSuggestion() {
        guard pendingWorkflowSuggestion != nil else { return }

        addAssistantMessage("Entendido, no guardaré esa rutina como workflow.")
        addSystemLog("Sugerencia de workflow rechazada")
        statusMessage = "Sugerencia descartada"
        pendingWorkflowSuggestion = nil
    }

    // MARK: - Confirmation buttons from UI

    @discardableResult
    func handleManualConfirmation() -> Bool {
        guard let pendingConfirmation else { return false }

        let confirmationText = "confirmar"
        let result = coordinator.handleInput(
            confirmationText,
            pendingConfirmation: pendingConfirmation,
            pendingWorkflowExecution: pendingWorkflowExecution,
            actionHistory: actionHistory
        )

        applyCoordinatorResult(result)

        // Si el workflow quedó reanudado, seguimos
        if let workflowExecution = pendingWorkflowExecution {
            let continuation = coordinator.continuePendingWorkflow(
                workflowExecution,
                invokedByName: false
            )
            applyCoordinatorResult(continuation)
        }

        return true
    }

    func cancelPendingConfirmation() {
        guard pendingConfirmation != nil else { return }

        let result = coordinator.handleInput(
            "cancelar",
            pendingConfirmation: pendingConfirmation,
            pendingWorkflowExecution: pendingWorkflowExecution,
            actionHistory: actionHistory
        )

        applyCoordinatorResult(result)
    }

    // MARK: - Workflow UI helpers

    func addWorkflowFromUI(name: String, commandsText: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let commands = commandsText
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanName.isEmpty else {
            statusMessage = "Ponle un nombre al workflow"
            return
        }

        guard !commands.isEmpty else {
            statusMessage = "Agrega al menos un comando"
            return
        }

        workflowStore.addWorkflow(name: cleanName, commands: commands)
        addAssistantMessage("Guardé el workflow '\(cleanName)' con \(commands.count) comando(s).")
        addSystemLog("Workflow guardado → \(cleanName)")
        statusMessage = "Workflow guardado"
    }

    func updateWorkflowFromUI(id: UUID, name: String, commands: [String]) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCommands = commands
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanName.isEmpty else {
            statusMessage = "El workflow necesita nombre"
            return
        }

        guard !cleanCommands.isEmpty else {
            statusMessage = "El workflow necesita al menos un comando"
            return
        }

        workflowStore.updateWorkflow(id: id, name: cleanName, commands: cleanCommands)
        addAssistantMessage("Actualicé el workflow '\(cleanName)'.")
        addSystemLog("Workflow actualizado → \(cleanName)")
        statusMessage = "Workflow actualizado"
    }

    func duplicateWorkflowFromUI(id: UUID) {
        guard let workflow = workflowStore.workflow(id: id) else { return }
        workflowStore.duplicateWorkflow(id: id)
        addAssistantMessage("Dupliqué el workflow '\(workflow.name)'.")
        addSystemLog("Workflow duplicado → \(workflow.name)")
        statusMessage = "Workflow duplicado"
    }

    func deleteWorkflowFromUI(name: String) {
        pendingConfirmation = PendingConfirmation(
            action: .deleteWorkflow(name: name),
            createdAt: Date(),
            reason: "Vas a borrar el workflow '\(name)'. Escribe CONFIRMAR para continuar.",
            workflowContext: nil
        )

        addAssistantMessage("Vas a borrar el workflow '\(name)'. Escribe CONFIRMAR para continuar.")
        addSystemLog("Confirmación solicitada para borrar workflow → \(name)")
        statusMessage = "Esperando confirmación"
    }

    func runWorkflowFromUI(name: String) {
        let result = coordinator.runWorkflow(named: name)
        applyCoordinatorResult(result)

        if let workflowExecution = pendingWorkflowExecution {
            let continuation = coordinator.continuePendingWorkflow(
                workflowExecution,
                invokedByName: false
            )
            applyCoordinatorResult(continuation)
        }
    }

    // MARK: - Memory UI helpers

    func addMemoryAliasFromUI(alias: String, value: String, kind: MemoryAliasKind) {
        let cleanAlias = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanAlias.isEmpty, !cleanValue.isEmpty else {
            statusMessage = "Completa alias y valor"
            return
        }

        let action: AssistantAction

        switch kind {
        case .folder:
            let normalizedPath = NSString(string: cleanValue).expandingTildeInPath
            action = .rememberFolderAlias(alias: cleanAlias, path: normalizedPath)

        case .app:
            let normalizedApp = NameNormalizer.normalizeApp(cleanValue)
            action = .rememberAppAlias(alias: cleanAlias, appName: normalizedApp)

        case .website:
            action = .rememberWebsiteAlias(alias: cleanAlias, url: cleanValue)
        }

        switch validator.validate(action) {
        case .invalid(let message):
            addSystemLog("Guardado de alias inválido → \(message)")
            addAssistantMessage(message)
            statusMessage = message

        case .warning(let message):
            pendingConfirmation = PendingConfirmation(
                action: action,
                createdAt: Date(),
                reason: message,
                workflowContext: nil
            )

            addSystemLog("Guardado de alias con warning → \(message)")
            addAssistantMessage("\(message) Escribe CONFIRMAR para continuar o CANCELAR para abortar.")
            statusMessage = "Esperando confirmación"

        case .valid:
            let execution = executor.execute(action)
            addSystemLog(execution.technicalMessage)
            addAssistantMessage(execution.userMessage)
            statusMessage = execution.userMessage
        }
    }

    func deleteMemoryAlias(alias: String, kind: MemoryAliasKind) {
        let action: AssistantAction
        let message: String

        switch kind {
        case .folder:
            action = .forgetFolderAlias(alias: alias)
            message = "Vas a eliminar la carpeta guardada '\(alias)'. Escribe CONFIRMAR para continuar."

        case .app:
            action = .forgetAppAlias(alias: alias)
            message = "Vas a eliminar la app guardada '\(alias)'. Escribe CONFIRMAR para continuar."

        case .website:
            action = .forgetWebsiteAlias(alias: alias)
            message = "Vas a eliminar el sitio guardado '\(alias)'. Escribe CONFIRMAR para continuar."
        }

        pendingConfirmation = PendingConfirmation(
            action: action,
            createdAt: Date(),
            reason: message,
            workflowContext: nil
        )

        addAssistantMessage(message)
        addSystemLog("Confirmación solicitada para borrar alias → \(alias)")
        statusMessage = "Esperando confirmación"
    }

    func clearAllMemoryFromUI() {
        pendingConfirmation = PendingConfirmation(
            action: .clearMemory,
            createdAt: Date(),
            reason: "Vas a borrar toda la memoria desde la interfaz. Escribe CONFIRMAR para continuar.",
            workflowContext: nil
        )

        addAssistantMessage("Vas a borrar toda la memoria desde la interfaz. Escribe CONFIRMAR para continuar.")
        addSystemLog("Confirmación solicitada para borrar toda la memoria")
        statusMessage = "Esperando confirmación"
    }

    // MARK: - Identity UI helpers

    func setAssistantNameFromUI(_ name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !clean.isEmpty else {
            statusMessage = "Escribe un nombre válido"
            return
        }

        let success = identityStore.setNameOnce(clean)
        let responder = AssistantNaturalResponder(
            style: AssistantResponseStyle(
                assistantName: identityStore.assistantName,
                wasInvokedByName: false
            )
        )

        if success {
            addAssistantMessage(responder.respondToNameSetSuccess(clean))
            addSystemLog("Nombre del asistente fijado desde UI → \(clean)")
            statusMessage = "Nombre guardado"
        } else {
            addAssistantMessage(
                responder.respondToNameSetRejected(currentName: identityStore.assistantName)
            )
            addSystemLog("Intento rechazado de cambiar nombre del asistente desde UI")
            statusMessage = "Nombre bloqueado"
        }
    }

    // MARK: - Index rebuild helpers

    func rebuildInstalledAppsIndex() {
        installedAppsIndex.rebuild()
        addAssistantMessage("Listo, actualicé el índice de apps instaladas.")
        addSystemLog("Índice de apps reconstruido")
        statusMessage = "Índice actualizado"
    }

    func rebuildUserFilesIndex() {
        userFilesIndex.rebuild()
        addAssistantMessage("Listo, actualicé el índice de archivos.")
        addSystemLog("Índice de archivos reconstruido")
        statusMessage = "Índice actualizado"
    }

    // MARK: - Action history

    private func registerExecutedCommandForPatternDetection(_ command: String) {
        let normalized = normalizedCommandForPatternDetection(command)

        guard !normalized.isEmpty else { return }

        let entry = ActionHistoryEntry(
            command: command,
            normalizedCommand: normalized
        )

        actionHistory.append(entry)

        if actionHistory.count > 40 {
            actionHistory.removeFirst(actionHistory.count - 40)
        }
    }

    private func normalizedCommandForPatternDetection(_ command: String) -> String {
        command
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
