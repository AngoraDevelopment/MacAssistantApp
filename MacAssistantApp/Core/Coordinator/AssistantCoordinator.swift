//
//  AssistantCoordinator.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

@MainActor
final class AssistantCoordinator {

    private let dependencies: AssistantCoordinatorDependencies

    private let knowledgeParser = AssistantKnowledgeParser()
    private let identityParser = AssistantIdentityCommandParser()
    private let socialParser = AssistantSocialParser()
    private let wakeParserProvider: () -> AssistantWakeParser

    private let conversationalCleaner = ConversationalCommandCleaner()
    private let chainedCommandParser = ChainedCommandParser()
    private let compoundCommandParser = CompoundCommandParser()
    private let advancedCompoundParser = AdvancedCompoundCommandParser()
    private let advancedFollowUpParser = AdvancedFollowUpParser()

    private let suggestionEngine = SuggestionEngine()
    private let actionPatternDetector = ActionPatternDetector()
    
    private let actionPlanner: ActionPlanner
    private let actionPlanExecutor: ActionPlanExecutor

    init(dependencies: AssistantCoordinatorDependencies) {
        self.dependencies = dependencies
        self.wakeParserProvider = {
            AssistantWakeParser(assistantName: dependencies.identityStore.assistantName)
        }
        self.actionPlanner = ActionPlanner(
            parser: dependencies.parser,
            memoryStore: dependencies.memoryStore
        )

        self.actionPlanExecutor = ActionPlanExecutor(
            validator: dependencies.validator,
            executor: dependencies.executor
        )
    }

    func handleInput(
        _ originalCommand: String,
        pendingConfirmation: PendingConfirmation?,
        pendingWorkflowExecution: PendingWorkflowExecution?,
        actionHistory: [ActionHistoryEntry]
    ) -> AssistantCoordinatorResult {

        var result = AssistantCoordinatorResult()
        let trimmed = originalCommand.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            result.statusMessage = "Escribe un mensaje primero"
            return result
        }

        let wakeResult = wakeParserProvider().parse(trimmed)

        let cleanedConversation = conversationalCleaner.clean(
            wakeResult.cleanedInput.isEmpty ? trimmed : wakeResult.cleanedInput,
            assistantName: dependencies.identityStore.assistantName
        )

        let naturalResponder = AssistantNaturalResponder(
            style: AssistantResponseStyle(
                assistantName: dependencies.identityStore.assistantName,
                wasInvokedByName: wakeResult.wasInvoked
            )
        )

        if wakeResult.wasInvoked && cleanedConversation.isEmpty {
            result.assistantMessages.append(naturalResponder.responseForOnlyNameInvocation())
            result.systemLogs.append("Invocación por nombre sin comando")
            result.statusMessage = "Respuesta enviada"
            return result
        }

        if let confirmationResult = handleConfirmationInput(
            cleanedConversation.isEmpty ? trimmed : cleanedConversation,
            pendingConfirmation: pendingConfirmation
        ) {
            return confirmationResult
        }

        let commands = chainedCommandParser.splitCommands(
            cleanedConversation.isEmpty ? trimmed : cleanedConversation
        )

        var localActionHistory = actionHistory

        for command in commands {
            let singleResult = processSingleCommand(
                command,
                naturalResponder: naturalResponder,
                pendingWorkflowExecution: result.pendingWorkflowExecution ?? pendingWorkflowExecution
            )

            result.assistantMessages.append(contentsOf: singleResult.assistantMessages)
            result.systemLogs.append(contentsOf: singleResult.systemLogs)
            result.statusMessage = singleResult.statusMessage
            result.suggestions = singleResult.suggestions
            result.pendingConfirmation = singleResult.pendingConfirmation
            result.pendingWorkflowExecution = singleResult.pendingWorkflowExecution
            result.didExecuteAction = result.didExecuteAction || singleResult.didExecuteAction
            result.executedCommandsForPatternDetection.append(contentsOf: singleResult.executedCommandsForPatternDetection)

            if !singleResult.executedCommandsForPatternDetection.isEmpty {
                for command in singleResult.executedCommandsForPatternDetection {
                    localActionHistory.append(
                        ActionHistoryEntry(
                            command: command,
                            normalizedCommand: normalizedCommandForPatternDetection(command)
                        )
                    )
                }

                if let suggestion = evaluateWorkflowPatternSuggestion(from: localActionHistory) {
                    result.pendingWorkflowSuggestion = suggestion
                    result.assistantMessages.append(
                        "Veo que has repetido una secuencia de comandos. ¿Quieres que la guarde como workflow '\(suggestion.suggestedName)'?"
                    )
                    result.systemLogs.append("Sugerencia automática de workflow → \(suggestion.suggestedName)")
                }
            }

            if result.pendingConfirmation != nil {
                break
            }
        }

        return result
    }

    // MARK: - Confirmation

    private func handleConfirmationInput(
        _ input: String,
        pendingConfirmation: PendingConfirmation?
    ) -> AssistantCoordinatorResult? {
        guard let pendingConfirmation else { return nil }

        var result = AssistantCoordinatorResult()
        let lower = input.lowercased()

        if lower == "confirmar" || lower == "confirm" {
            let execution = dependencies.executor.execute(pendingConfirmation.action)

            result.systemLogs.append("Confirmación recibida → \(String(describing: pendingConfirmation.action))")
            result.systemLogs.append(execution.technicalMessage)
            result.assistantMessages.append(execution.userMessage)
            result.statusMessage = execution.userMessage
            result.suggestions = refreshedSuggestions(after: pendingConfirmation.action, result: execution)

            if execution.success {
                updateConversationContext(for: pendingConfirmation.action)
            }

            if let workflowContext = pendingConfirmation.workflowContext {
                result.pendingWorkflowExecution = workflowContext
                result.assistantMessages.append("Listo. Reanudo el workflow '\(workflowContext.workflowName)'.")
            }

            return result
        }

        if lower == "cancelar" || lower == "cancel" {
            if let workflowContext = pendingConfirmation.workflowContext {
                result.assistantMessages.append("Cancelé el workflow '\(workflowContext.workflowName)'.")
                result.systemLogs.append("Workflow cancelado → \(workflowContext.workflowName)")
            } else {
                result.assistantMessages.append("Acción cancelada.")
                result.systemLogs.append("Acción cancelada → \(String(describing: pendingConfirmation.action))")
            }

            result.statusMessage = "Acción cancelada"
            return result
        }

        result.assistantMessages.append("Hay una acción pendiente. Escribe CONFIRMAR o CANCELAR.")
        result.statusMessage = "Esperando confirmación"
        return result
    }

    // MARK: - Single command processing

    private func processSingleCommand(
        _ command: String,
        naturalResponder: AssistantNaturalResponder,
        pendingWorkflowExecution: PendingWorkflowExecution?
    ) -> AssistantCoordinatorResult {

        var result = AssistantCoordinatorResult()

        if let identityCommand = identityParser.parse(command) {
            switch identityCommand {
            case .askName:
                result.assistantMessages.append(naturalResponder.respondToNameQuestion())
                result.statusMessage = "Respuesta enviada"
                return result

            case .setName(let name):
                let success = dependencies.identityStore.setNameOnce(name)

                let updatedResponder = AssistantNaturalResponder(
                    style: AssistantResponseStyle(
                        assistantName: dependencies.identityStore.assistantName,
                        wasInvokedByName: naturalResponder.style.wasInvokedByName
                    )
                )

                if success {
                    result.assistantMessages.append(updatedResponder.respondToNameSetSuccess(name))
                    result.systemLogs.append("Nombre del asistente fijado → \(name)")
                    result.statusMessage = "Nombre guardado"
                } else {
                    result.assistantMessages.append(
                        updatedResponder.respondToNameSetRejected(currentName: dependencies.identityStore.assistantName)
                    )
                    result.systemLogs.append("Intento rechazado de cambiar nombre del asistente")
                    result.statusMessage = "Nombre bloqueado"
                }

                return result
            }
        }

        let socialIntent = socialParser.parse(command)
        if let socialResponse = naturalResponder.respond(to: socialIntent) {
            result.assistantMessages.append(socialResponse)
            result.statusMessage = "Respuesta enviada"
            return result
        }

        let knowledgeIntent = knowledgeParser.parse(command)
        if let knowledgeResponse = knowledgeResponse(for: knowledgeIntent, responder: naturalResponder) {
            result.assistantMessages.append(knowledgeResponse)
            result.statusMessage = "Respuesta enviada"
            return result
        }

        if let followUpResult = handleConversationalFollowUp(command, responder: naturalResponder) {
            return followUpResult
        }

        if let plan = actionPlanner.buildPlan(from: command) {
            let planResult = actionPlanExecutor.executePlan(
                plan,
                naturalize: { naturalResponder.personalizeExecutionMessage($0) },
                updateContext: { [weak self] action in
                    self?.updateConversationContext(for: action)
                },
                refreshSuggestions: { [weak self] action, execution in
                    self?.refreshedSuggestions(after: action, result: execution) ?? []
                }
            )

            var coordinatorResult = AssistantCoordinatorResult()
            coordinatorResult.assistantMessages = planResult.assistantMessages
            coordinatorResult.systemLogs = planResult.systemLogs
            coordinatorResult.statusMessage = planResult.statusMessage
            coordinatorResult.pendingConfirmation = planResult.pendingConfirmation
            coordinatorResult.suggestions = planResult.suggestions
            coordinatorResult.didExecuteAction = planResult.didExecuteAction
            coordinatorResult.executedCommandsForPatternDetection = planResult.executedCommandsForPatternDetection

            return coordinatorResult
        }

        let parsed = dependencies.parser.parseWithTrace(command)
        let action = parsed.action

        if let trace = parsed.trace {
            result.systemLogs.append("Parser match → \(trace.parserName)")
        }

        result.systemLogs.append("Acción detectada → \(String(describing: action))")

        let executionResult = executeAction(
            action,
            naturalResponder: naturalResponder,
            originalCommandForPattern: command
        )

        result.assistantMessages.append(contentsOf: executionResult.assistantMessages)
        result.systemLogs.append(contentsOf: executionResult.systemLogs)
        result.statusMessage = executionResult.statusMessage
        result.pendingConfirmation = executionResult.pendingConfirmation
        result.pendingWorkflowExecution = executionResult.pendingWorkflowExecution
        result.suggestions = executionResult.suggestions
        result.didExecuteAction = executionResult.didExecuteAction
        result.executedCommandsForPatternDetection = executionResult.executedCommandsForPatternDetection

        return result
    }

    // MARK: - Action execution

    private func executeAction(
        _ action: AssistantAction,
        naturalResponder: AssistantNaturalResponder,
        originalCommandForPattern: String
    ) -> AssistantCoordinatorResult {

        var result = AssistantCoordinatorResult()

        if case .runWorkflow(let name) = action {
            return runWorkflow(named: name)
        }

        switch dependencies.validator.validate(action) {
        case .invalid(let message):
            result.systemLogs.append("Validación fallida → \(message)")
            result.assistantMessages.append(message)
            result.statusMessage = message
            return result

        case .warning(let message):
            result.pendingConfirmation = PendingConfirmation(
                action: action,
                createdAt: Date(),
                reason: message,
                workflowContext: nil
            )
            result.systemLogs.append("Warning → \(message)")
            result.assistantMessages.append("\(message) Escribe CONFIRMAR para continuar o CANCELAR para abortar.")
            result.statusMessage = "Esperando confirmación"
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
            return result
        }

        let execution = dependencies.executor.execute(action)

        if execution.success {
            updateConversationContext(for: action)
            result.didExecuteAction = true
            result.executedCommandsForPatternDetection = [originalCommandForPattern]
        }

        result.systemLogs.append(execution.technicalMessage)
        result.assistantMessages.append(naturalResponder.personalizeExecutionMessage(execution.userMessage))
        result.statusMessage = execution.userMessage
        result.suggestions = refreshedSuggestions(after: action, result: execution)

        return result
    }

    @discardableResult
    private func executeActionSequence(
        _ actions: [AssistantAction],
        naturalResponder: AssistantNaturalResponder,
        originalCommandsForPattern: [String]
    ) -> AssistantCoordinatorResult {

        var result = AssistantCoordinatorResult()
        var didExecuteSomething = false

        for action in actions {
            result.systemLogs.append("Acción compuesta → \(String(describing: action))")

            switch dependencies.validator.validate(action) {
            case .invalid(let message):
                result.systemLogs.append("Validación fallida → \(message)")
                result.assistantMessages.append(message)
                result.statusMessage = message
                result.didExecuteAction = didExecuteSomething
                return result

            case .warning(let message):
                result.pendingConfirmation = PendingConfirmation(
                    action: action,
                    createdAt: Date(),
                    reason: message,
                    workflowContext: nil
                )
                result.systemLogs.append("Warning en acción compuesta → \(message)")
                result.assistantMessages.append("\(message) Escribe CONFIRMAR para continuar o CANCELAR para abortar.")
                result.statusMessage = "Esperando confirmación"
                result.didExecuteAction = didExecuteSomething
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
                result.didExecuteAction = didExecuteSomething
                return result
            }

            let execution = dependencies.executor.execute(action)

            if execution.success {
                updateConversationContext(for: action)
                didExecuteSomething = true
            }

            result.systemLogs.append(execution.technicalMessage)
            result.assistantMessages.append(naturalResponder.personalizeExecutionMessage(execution.userMessage))
            result.statusMessage = execution.userMessage
            result.suggestions = refreshedSuggestions(after: action, result: execution)

            if !execution.success {
                result.didExecuteAction = didExecuteSomething
                return result
            }
        }

        result.didExecuteAction = didExecuteSomething
        if didExecuteSomething {
            result.executedCommandsForPatternDetection = originalCommandsForPattern
        }
        return result
    }

    // MARK: - Workflow execution

    func runWorkflow(named name: String) -> AssistantCoordinatorResult {
        var result = AssistantCoordinatorResult()

        guard let workflow = dependencies.workflowStore.workflow(named: name) else {
            let message = "No encontré el workflow '\(name)'."
            result.assistantMessages.append(message)
            result.systemLogs.append("Workflow no encontrado → \(name)")
            result.statusMessage = message
            return result
        }

        let execution = PendingWorkflowExecution(
            workflowName: workflow.name,
            commands: workflow.commands,
            currentIndex: 0
        )

        result.pendingWorkflowExecution = execution
        result.assistantMessages.append("Ejecutando workflow '\(workflow.name)'.")
        result.systemLogs.append("Workflow iniciado → \(workflow.name)")
        result.statusMessage = "Workflow iniciado"
        return continuePendingWorkflow(execution, invokedByName: false)
    }

    func continuePendingWorkflow(
        _ execution: PendingWorkflowExecution,
        invokedByName: Bool
    ) -> AssistantCoordinatorResult {
        var result = AssistantCoordinatorResult()
        var currentExecution = execution

        let naturalResponder = AssistantNaturalResponder(
            style: AssistantResponseStyle(
                assistantName: dependencies.identityStore.assistantName,
                wasInvokedByName: invokedByName
            )
        )

        while currentExecution.currentIndex < currentExecution.commands.count {
            let command = currentExecution.commands[currentExecution.currentIndex]
            result.systemLogs.append("Workflow comando → \(command)")

            let parsed = dependencies.parser.parseWithTrace(command)
            let action = parsed.action

            if let trace = parsed.trace {
                result.systemLogs.append("Workflow parser match → \(trace.parserName)")
            }

            result.systemLogs.append("Workflow acción detectada → \(String(describing: action))")

            switch dependencies.validator.validate(action) {
            case .invalid(let message):
                result.systemLogs.append("Workflow detenido por validación → \(message)")
                result.assistantMessages.append("Detuve el workflow '\(currentExecution.workflowName)'. \(message)")
                result.statusMessage = "Workflow detenido"
                return result

            case .warning(let message):
                let pausedExecution = PendingWorkflowExecution(
                    workflowName: currentExecution.workflowName,
                    commands: currentExecution.commands,
                    currentIndex: currentExecution.currentIndex + 1
                )

                result.pendingConfirmation = PendingConfirmation(
                    action: action,
                    createdAt: Date(),
                    reason: "Workflow '\(currentExecution.workflowName)': \(message)",
                    workflowContext: pausedExecution
                )

                result.assistantMessages.append(
                    "El workflow '\(currentExecution.workflowName)' se pausó. \(message) Escribe CONFIRMAR para continuar o CANCELAR para abortar."
                )
                result.systemLogs.append("Workflow pausado por warning → \(message)")
                result.statusMessage = "Workflow pausado"
                return result

            case .valid:
                break
            }

            if action.requiresConfirmation {
                let pausedExecution = PendingWorkflowExecution(
                    workflowName: currentExecution.workflowName,
                    commands: currentExecution.commands,
                    currentIndex: currentExecution.currentIndex + 1
                )

                result.pendingConfirmation = PendingConfirmation(
                    action: action,
                    createdAt: Date(),
                    reason: "Workflow '\(currentExecution.workflowName)': \(action.confirmationMessage)",
                    workflowContext: pausedExecution
                )

                result.assistantMessages.append(
                    "El workflow '\(currentExecution.workflowName)' necesita confirmación. \(action.confirmationMessage)"
                )
                result.systemLogs.append("Workflow pausado por confirmación → \(String(describing: action))")
                result.statusMessage = "Workflow pausado"
                return result
            }

            let executionResult = dependencies.executor.execute(action)

            if executionResult.success {
                updateConversationContext(for: action)
            }

            result.systemLogs.append(executionResult.technicalMessage)
            result.assistantMessages.append(executionResult.userMessage)
            result.suggestions = refreshedSuggestions(after: action, result: executionResult)

            currentExecution.currentIndex += 1
            result.pendingWorkflowExecution = currentExecution
        }

        result.assistantMessages.append("Workflow '\(currentExecution.workflowName)' completado.")
        result.systemLogs.append("Workflow completado → \(currentExecution.workflowName)")
        result.statusMessage = "Workflow completado"
        result.pendingWorkflowExecution = nil
        return result
    }

    // MARK: - Follow-up

    private func handleConversationalFollowUp(
        _ input: String,
        responder: AssistantNaturalResponder
    ) -> AssistantCoordinatorResult? {
        let intent = advancedFollowUpParser.parse(input)
        let context = dependencies.conversationContextStore.context

        switch intent {
        case .reopenLastEntity:
            switch context.lastEntityKind {
            case .app:
                guard let appName = context.lastOpenedAppName else { return simpleMessage("No tengo una app reciente para volver a abrir.") }
                return executeAction(.openApp(name: appName), naturalResponder: responder, originalCommandForPattern: input)

            case .folder:
                guard let folderPath = context.lastOpenedFolderPath else { return simpleMessage("No tengo una carpeta reciente para volver a abrir.") }
                return executeAction(.openFolder(path: folderPath), naturalResponder: responder, originalCommandForPattern: input)

            case .website:
                guard let urlString = context.lastOpenedWebsiteURL, let url = URL(string: urlString) else {
                    return simpleMessage("No tengo un sitio reciente para volver a abrir.")
                }
                return executeAction(.openWebsite(url: url), naturalResponder: responder, originalCommandForPattern: input)

            case .search:
                guard let query = context.lastSearchQuery else { return simpleMessage("No tengo una búsqueda reciente para repetir.") }
                return executeAction(.searchGoogle(query: query), naturalResponder: responder, originalCommandForPattern: input)

            case .workflow:
                guard let workflowName = context.lastWorkflowName else { return simpleMessage("No tengo un workflow reciente para repetir.") }
                return runWorkflow(named: workflowName)

            case .file:
                guard let path = context.lastEntityValue else { return simpleMessage("No tengo un archivo reciente para volver a abrir.") }
                return executeAction(.openFile(path: path), naturalResponder: responder, originalCommandForPattern: input)

            case .unknown:
                return simpleMessage("No tengo suficiente contexto para saber a qué te refieres con eso.")
            }

        case .closeLastApp:
            guard let appName = context.lastOpenedAppName else {
                return simpleMessage("No tengo una app reciente en el contexto para cerrar.")
            }
            return executeAction(.quitApp(name: appName), naturalResponder: responder, originalCommandForPattern: input)

        case .createFolderInLastFolder(let name):
            guard let folderPath = context.lastOpenedFolderPath else {
                return simpleMessage("No tengo una carpeta reciente donde crear eso.")
            }
            return executeAction(
                .createFolder(basePath: folderPath, folderName: name),
                naturalResponder: responder,
                originalCommandForPattern: input
            )

        case .searchLastQueryAgain:
            guard let query = context.lastSearchQuery else {
                return simpleMessage("No tengo una búsqueda reciente para repetir.")
            }
            return executeAction(.searchGoogle(query: query), naturalResponder: responder, originalCommandForPattern: input)

        case .openLastWebsiteAgain:
            guard let urlString = context.lastOpenedWebsiteURL, let url = URL(string: urlString) else {
                return simpleMessage("No tengo un sitio reciente para volver a abrir.")
            }
            return executeAction(.openWebsite(url: url), naturalResponder: responder, originalCommandForPattern: input)

        case .openLastFolderAgain:
            guard let folderPath = context.lastOpenedFolderPath else {
                return simpleMessage("No tengo una carpeta reciente para volver a abrir.")
            }
            return executeAction(.openFolder(path: folderPath), naturalResponder: responder, originalCommandForPattern: input)

        case .openLastAppAgain:
            guard let appName = context.lastOpenedAppName else {
                return simpleMessage("No tengo una app reciente para volver a abrir.")
            }
            return executeAction(.openApp(name: appName), naturalResponder: responder, originalCommandForPattern: input)

        case .askLastThing:
            if let summary = context.lastActionSummary {
                return simpleMessage("Lo último que tengo en contexto fue: \(summary).")
            } else {
                return simpleMessage("Todavía no tengo una acción reciente en contexto.")
            }

        case .unknown:
            return nil
        }
    }

    // MARK: - Knowledge + context + suggestions

    private func knowledgeResponse(
        for intent: AssistantKnowledgeIntent,
        responder: AssistantNaturalResponder
    ) -> String? {
        switch intent {
        case .capabilities:
            return responder.capabilitiesResponse()
        case .memoryHelp:
            return responder.memoryHelpResponse()
        case .workflowHelp:
            return responder.workflowHelpResponse()
        case .commandsHelp:
            return responder.commandsHelpResponse()
        case .unknown:
            return nil
        }
    }

    private func updateConversationContext(for action: AssistantAction) {
        switch action {
        case .openFolder(let path):
            dependencies.conversationContextStore.setLastOpenedFolderPath(path)
            dependencies.conversationContextStore.setLastTopic("folder")
            dependencies.conversationContextStore.setLastActionSummary("open_folder")

        case .createFolder(let basePath, let folderName):
            let finalPath: String
            if let folderName, !folderName.isEmpty {
                finalPath = (basePath as NSString).appendingPathComponent(folderName)
            } else {
                finalPath = basePath
            }
            dependencies.conversationContextStore.setLastOpenedFolderPath(finalPath)
            dependencies.conversationContextStore.setLastTopic("folder")
            dependencies.conversationContextStore.setLastActionSummary("create_folder")

        case .openApp(let name):
            dependencies.conversationContextStore.setLastOpenedAppName(name)
            dependencies.conversationContextStore.setLastTopic("app")
            dependencies.conversationContextStore.setLastActionSummary("open_app")

        case .openWebsite(let url):
            dependencies.conversationContextStore.setLastOpenedWebsiteURL(url.absoluteString)
            dependencies.conversationContextStore.setLastTopic("website")
            dependencies.conversationContextStore.setLastActionSummary("open_website")

        case .runWorkflow(let name):
            dependencies.conversationContextStore.setLastWorkflowName(name)
            dependencies.conversationContextStore.setLastTopic("workflow")
            dependencies.conversationContextStore.setLastActionSummary("run_workflow")

        case .searchGoogle(let query):
            dependencies.conversationContextStore.setLastSearchQuery(query)
            dependencies.conversationContextStore.setLastTopic("search")
            dependencies.conversationContextStore.setLastActionSummary("search_google")

        case .searchInsideWebsite(_, let query):
            dependencies.conversationContextStore.setLastSearchQuery(query)
            dependencies.conversationContextStore.setLastTopic("search")
            dependencies.conversationContextStore.setLastActionSummary("search_inside_website")

        case .quitApp(let name):
            dependencies.conversationContextStore.setLastOpenedAppName(name)
            dependencies.conversationContextStore.setLastTopic("app")
            dependencies.conversationContextStore.setLastActionSummary("quit_app")

        case .openFile(let path):
            dependencies.conversationContextStore.setLastFilePath(path)
            dependencies.conversationContextStore.setLastActionSummary("open_file")

        case .findFile(let query):
            dependencies.conversationContextStore.setLastFileQuery(query)
            dependencies.conversationContextStore.setLastActionSummary("find_file")

        default:
            break
        }
    }

    private func refreshedSuggestions(
        after action: AssistantAction,
        result: AssistantExecutionResult
    ) -> [AssistantSuggestion] {
        suggestionEngine.suggestions(
            for: action,
            result: result,
            context: dependencies.conversationContextStore.context,
            assistantName: dependencies.identityStore.assistantName,
            memoryStore: dependencies.memoryStore,
            workflowStore: dependencies.workflowStore
        )
    }

    private func normalizedCommandForPatternDetection(_ command: String) -> String {
        command
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func evaluateWorkflowPatternSuggestion(from history: [ActionHistoryEntry]) -> WorkflowPatternSuggestion? {
        guard let suggestion = actionPatternDetector.detectSuggestion(from: history) else {
            return nil
        }

        let existing = dependencies.workflowStore.all().contains {
            $0.commands.map { normalizedCommandForPatternDetection($0) } ==
            suggestion.commands.map { normalizedCommandForPatternDetection($0) }
        }

        return existing ? nil : suggestion
    }

    private func simpleMessage(_ text: String) -> AssistantCoordinatorResult {
        var result = AssistantCoordinatorResult()
        result.assistantMessages.append(text)
        result.statusMessage = "Respuesta enviada"
        return result
    }
}
