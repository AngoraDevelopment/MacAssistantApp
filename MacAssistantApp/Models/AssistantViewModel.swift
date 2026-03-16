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
    @Published var suggestions: [AssistantSuggestion] = []
    @Published var pendingWorkflowSuggestion: WorkflowPatternSuggestion?

    let memoryStore: MemoryStore
    let workflowStore: WorkflowStore
    let identityStore: AssistantIdentityStore
    let conversationContextStore: ConversationContextStore
    let installedAppsIndex: InstalledAppsIndex
    let userFilesIndex: UserFilesIndex

    private let identityParser = AssistantIdentityCommandParser()
    private let socialParser = AssistantSocialParser()
    private let parser: CommandParser
    private let executor: SystemActionExecutor
    private let validator: AssistantActionValidator
    private let knowledgeParser = AssistantKnowledgeParser()
    private let followUpParser = ConversationFollowUpParser()
    private let conversationalCleaner = ConversationalCommandCleaner()
    private let chainedCommandParser = ChainedCommandParser()
    private let compoundCommandParser = CompoundCommandParser()
    private let advancedCompoundParser = AdvancedCompoundCommandParser()
    private let advancedFollowUpParser = AdvancedFollowUpParser()
    private let suggestionEngine = SuggestionEngine()
    private let actionPatternDetector = ActionPatternDetector()
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
        installedAppsIndex.rebuild()
        let userFilesIndex = UserFilesIndex()
        userFilesIndex.rebuild()

        self.userFilesIndex = userFilesIndex
        self.installedAppsIndex = installedAppsIndex
        self.identityStore = identityStore
        self.conversationContextStore = conversationContextStore
        self.memoryStore = memoryStore
        self.workflowStore = workflowStore
        self.parser = CommandParser(memoryStore: memoryStore, workflowStore: workflowStore)
        self.executor = SystemActionExecutor(
            memoryStore: memoryStore,
            workflowStore: workflowStore,
            installedAppsIndex: installedAppsIndex,
            userFilesIndex: userFilesIndex
        )

        self.validator = AssistantActionValidator(
            memoryStore: memoryStore,
            installedAppsIndex: installedAppsIndex,
            userFilesIndex: userFilesIndex
        )
        
        let initialName = identityStore.assistantName
            if let initialName {
                addAssistantMessage("Hola. Soy \(initialName). Estoy listo para ayudarte.")
            } else {
                addAssistantMessage("Hola. Estoy listo para ayudarte. Si quieres, puedes ponerme nombre una sola vez.")
            }
    }

    // MARK: - Main entry point

    func runCommand() {
        let originalCommand = commandText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !originalCommand.isEmpty else {
            statusMessage = "Escribe un mensaje primero"
            return
        }

        addUserMessage(originalCommand)

        let wakeResult = wakeParser().parse(originalCommand)

        let cleanedConversation = conversationalCleaner.clean(
            wakeResult.cleanedInput.isEmpty ? originalCommand : wakeResult.cleanedInput,
            assistantName: identityStore.assistantName
        )

        let naturalResponder = AssistantNaturalResponder(
            style: AssistantResponseStyle(
                assistantName: identityStore.assistantName,
                wasInvokedByName: wakeResult.wasInvoked
            )
        )

        if wakeResult.wasInvoked && cleanedConversation.isEmpty {
            let response = naturalResponder.responseForOnlyNameInvocation()
            addAssistantMessage(response)
            addSystemLog("Invocación por nombre sin comando")
            statusMessage = "Respuesta enviada"
            commandText = ""
            return
        }

        if handleConfirmationInput(cleanedConversation.isEmpty ? originalCommand : cleanedConversation) {
            commandText = ""
            return
        }

        let commands = chainedCommandParser.splitCommands(
            cleanedConversation.isEmpty ? originalCommand : cleanedConversation
        )

        for command in commands {
            let didExecute = processSingleCommand(command, naturalResponder: naturalResponder)

            if didExecute {
                registerExecutedCommandForPatternDetection(command)
            }

            if pendingConfirmation != nil {
                break
            }
        }

        commandText = ""
    }

    // MARK: - Chat / log helpers

    func addUserMessage(_ text: String) {
        chatMessages.insert(ChatMessage(role: .user, text: text), at: 0)
    }

    func addAssistantMessage(_ text: String) {
        chatMessages.insert(ChatMessage(role: .assistant, text: text), at: 0)
    }

    func addSystemLog(_ text: String) {
        systemLogs.insert(SystemLogEntry(text: text), at: 0)
    }
    
    func rebuildUserFilesIndex() {
        userFilesIndex.rebuild()
        addAssistantMessage("Listo, actualicé el índice de archivos.")
        addSystemLog("Índice de archivos reconstruido")
        statusMessage = "Índice actualizado"
    }
    
    // MARK: - Knowledge responses

    private func knowledgeResponse(for intent: AssistantKnowledgeIntent,responder: AssistantNaturalResponder) -> String? {
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

    // MARK: - Confirmation handling

    private func handleConfirmationInput(_ input: String) -> Bool {
        guard pendingConfirmation != nil else { return false }

        let lower = input.lowercased()

        if lower == "confirmar" || lower == "confirm" {
            return handleManualConfirmation()
        }

        if lower == "cancelar" || lower == "cancel" {
            cancelPendingConfirmation()
            return true
        }

        addAssistantMessage("Hay una acción pendiente. Escribe CONFIRMAR o CANCELAR.")
        statusMessage = "Esperando confirmación"
        return true
    }

    func handleManualConfirmation() -> Bool {
        guard let pendingConfirmation else { return false }

        let result = executor.execute(pendingConfirmation.action)
        addSystemLog("Confirmación recibida → \(String(describing: pendingConfirmation.action))")
        addSystemLog(result.technicalMessage)
        addAssistantMessage(result.userMessage)
        statusMessage = result.userMessage

        let workflowContext = pendingConfirmation.workflowContext
        self.pendingConfirmation = nil

        if let workflowContext {
            pendingWorkflowExecution = workflowContext
            addAssistantMessage("Listo. Reanudo el workflow '\(workflowContext.workflowName)'.")
            continuePendingWorkflow()
        }

        return true
    }

    func cancelPendingConfirmation() {
        guard let pendingConfirmation else { return }

        if let workflowContext = pendingConfirmation.workflowContext {
            addAssistantMessage("Cancelé el workflow '\(workflowContext.workflowName)'.")
            addSystemLog("Workflow cancelado → \(workflowContext.workflowName)")
            pendingWorkflowExecution = nil
        } else {
            addAssistantMessage("Acción cancelada.")
            addSystemLog("Acción cancelada → \(String(describing: pendingConfirmation.action))")
        }

        statusMessage = "Acción cancelada"
        self.pendingConfirmation = nil
    }

    // MARK: - Workflows

    func runWorkflow(named name: String) {
        guard let workflow = workflowStore.workflow(named: name) else {
            let message = "No encontré el workflow '\(name)'."
            addAssistantMessage(message)
            addSystemLog("Workflow no encontrado → \(name)")
            statusMessage = message
            return
        }

        let execution = PendingWorkflowExecution(
            workflowName: workflow.name,
            commands: workflow.commands,
            currentIndex: 0
        )

        pendingWorkflowExecution = execution
        addAssistantMessage("Ejecutando workflow '\(workflow.name)'.")
        addSystemLog("Workflow iniciado → \(workflow.name)")
        continuePendingWorkflow()
    }

    func continuePendingWorkflow() {
        guard var execution = pendingWorkflowExecution else { return }

        while execution.currentIndex < execution.commands.count {
            let command = execution.commands[execution.currentIndex]
            addSystemLog("Workflow comando → \(command)")

            let action = parser.parse(command)
            addSystemLog("Workflow acción detectada → \(String(describing: action))")

            switch validator.validate(action) {
            case .invalid(let message):
                addSystemLog("Workflow detenido por validación → \(message)")
                addAssistantMessage("Detuve el workflow '\(execution.workflowName)'. \(message)")
                statusMessage = "Workflow detenido"
                pendingWorkflowExecution = nil
                return

            case .warning(let message):
                let pausedExecution = PendingWorkflowExecution(
                    workflowName: execution.workflowName,
                    commands: execution.commands,
                    currentIndex: execution.currentIndex + 1
                )

                pendingConfirmation = PendingConfirmation(
                    action: action,
                    createdAt: Date(),
                    reason: "Workflow '\(execution.workflowName)': \(message)",
                    workflowContext: pausedExecution
                )

                pendingWorkflowExecution = nil
                addAssistantMessage("El workflow '\(execution.workflowName)' se pausó. \(message) Escribe CONFIRMAR para continuar o CANCELAR para abortar.")
                addSystemLog("Workflow pausado por warning → \(message)")
                statusMessage = "Workflow pausado"
                return

            case .valid:
                break
            }

            if action.requiresConfirmation {
                let pausedExecution = PendingWorkflowExecution(
                    workflowName: execution.workflowName,
                    commands: execution.commands,
                    currentIndex: execution.currentIndex + 1
                )

                pendingConfirmation = PendingConfirmation(
                    action: action,
                    createdAt: Date(),
                    reason: "Workflow '\(execution.workflowName)': \(action.confirmationMessage)",
                    workflowContext: pausedExecution
                )

                pendingWorkflowExecution = nil
                addAssistantMessage("El workflow '\(execution.workflowName)' necesita confirmación. \(action.confirmationMessage)")
                addSystemLog("Workflow pausado por confirmación → \(String(describing: action))")
                statusMessage = "Workflow pausado"
                return
            }

            let result = executor.execute(action)
            if result.success {
                updateConversationContext(for: action)
            }
            addSystemLog(result.technicalMessage)
            addAssistantMessage(result.userMessage)
            refreshSuggestions(
                after: action,
                result: result,
                naturalResponder: AssistantNaturalResponder(
                    style: AssistantResponseStyle(
                        assistantName: identityStore.assistantName,
                        wasInvokedByName: false
                    )
                )
            )
        }

        addAssistantMessage("Workflow '\(execution.workflowName)' completado.")
        addSystemLog("Workflow completado → \(execution.workflowName)")
        statusMessage = "Workflow completado"
        pendingWorkflowExecution = nil
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
            let result = executor.execute(action)
            addSystemLog(result.technicalMessage)
            addAssistantMessage(result.userMessage)
            statusMessage = result.userMessage
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
        runWorkflow(named: name)
    }
    
    func setAssistantNameFromUI(_ name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !clean.isEmpty else {
            statusMessage = "Escribe un nombre válido"
            return
        }

        let success = identityStore.setNameOnce(clean)
        let responder = AssistantPersonaResponder(assistantName: identityStore.assistantName)

        if success {
            let message = responder.respondToNameSetSuccess(clean)
            addAssistantMessage(message)
            addSystemLog("Nombre del asistente fijado desde UI → \(clean)")
            statusMessage = "Nombre guardado"
        } else {
            let message = responder.respondToNameSetRejected(currentName: identityStore.assistantName)
            addAssistantMessage(message)
            addSystemLog("Intento rechazado de cambiar nombre del asistente desde UI")
            statusMessage = "Nombre bloqueado"
        }
    }
    
    private func wakeParser() -> AssistantWakeParser {
        AssistantWakeParser(assistantName: identityStore.assistantName)
    }
    
    private func updateConversationContext(for action: AssistantAction) {
        switch action {
        case .openFolder(let path):
            conversationContextStore.setLastOpenedFolderPath(path)
            conversationContextStore.setLastTopic("folder")
            conversationContextStore.setLastActionSummary("open_folder")

        case .createFolder(let basePath, let folderName):
            let finalPath: String
            if let folderName, !folderName.isEmpty {
                finalPath = (basePath as NSString).appendingPathComponent(folderName)
            } else {
                finalPath = basePath
            }

            conversationContextStore.setLastOpenedFolderPath(finalPath)
            conversationContextStore.setLastTopic("folder")
            conversationContextStore.setLastActionSummary("create_folder")
            
        case .openFile(let path):
            conversationContextStore.setLastFilePath(path)
            conversationContextStore.setLastActionSummary("open_file")

        case .findFile(let query):
            conversationContextStore.setLastFileQuery(query)
            conversationContextStore.setLastActionSummary("find_file")
            
        case .openApp(let name):
            conversationContextStore.setLastOpenedAppName(name)
            conversationContextStore.setLastTopic("app")
            conversationContextStore.setLastActionSummary("open_app")

        case .openWebsite(let url):
            conversationContextStore.setLastOpenedWebsiteURL(url.absoluteString)
            conversationContextStore.setLastTopic("website")
            conversationContextStore.setLastActionSummary("open_website")

        case .runWorkflow(let name):
            conversationContextStore.setLastWorkflowName(name)
            conversationContextStore.setLastTopic("workflow")
            conversationContextStore.setLastActionSummary("run_workflow")

        case .searchGoogle(let query):
            conversationContextStore.setLastSearchQuery(query)
            conversationContextStore.setLastTopic("search")
            conversationContextStore.setLastActionSummary("search_google")

        case .searchInsideWebsite(_, let query):
            conversationContextStore.setLastSearchQuery(query)
            conversationContextStore.setLastTopic("search")
            conversationContextStore.setLastActionSummary("search_inside_website")

        case .quitApp(let name):
            conversationContextStore.setLastOpenedAppName(name)
            conversationContextStore.setLastTopic("app")
            conversationContextStore.setLastActionSummary("quit_app")

        default:
            break
        }
    }
    
    private func handleConversationalFollowUp(_ input: String, responder: AssistantNaturalResponder) -> Bool {
        let intent = advancedFollowUpParser.parse(input)
        let context = conversationContextStore.context

        switch intent {
        case .reopenLastEntity:
            switch context.lastEntityKind {
            case .app:
                guard let appName = context.lastOpenedAppName else {
                    addAssistantMessage("No tengo una app reciente para volver a abrir.")
                    return true
                }
                return executeFollowUpAction(.openApp(name: appName), responder: responder)

            case .folder:
                guard let folderPath = context.lastOpenedFolderPath else {
                    addAssistantMessage("No tengo una carpeta reciente para volver a abrir.")
                    return true
                }
                return executeFollowUpAction(.openFolder(path: folderPath), responder: responder)

            case .website:
                guard let urlString = context.lastOpenedWebsiteURL,
                      let url = URL(string: urlString) else {
                    addAssistantMessage("No tengo un sitio reciente para volver a abrir.")
                    return true
                }
                return executeFollowUpAction(.openWebsite(url: url), responder: responder)

            case .search:
                guard let query = context.lastSearchQuery else {
                    addAssistantMessage("No tengo una búsqueda reciente para repetir.")
                    return true
                }
                return executeFollowUpAction(.searchGoogle(query: query), responder: responder)

            case .workflow:
                guard let workflowName = context.lastWorkflowName else {
                    addAssistantMessage("No tengo un workflow reciente para repetir.")
                    return true
                }
                runWorkflow(named: workflowName)
                return true

            case .unknown:
                addAssistantMessage("No tengo suficiente contexto para saber a qué te refieres con eso.")
                return true
            case .file:
                <#code#>
            }

        case .closeLastApp:
            guard let appName = context.lastOpenedAppName else {
                addAssistantMessage("No tengo una app reciente en el contexto para cerrar.")
                return true
            }
            return executeFollowUpAction(.quitApp(name: appName), responder: responder)

        case .createFolderInLastFolder(let name):
            guard let folderPath = context.lastOpenedFolderPath else {
                addAssistantMessage("No tengo una carpeta reciente donde crear eso.")
                return true
            }
            return executeFollowUpAction(.createFolder(basePath: folderPath, folderName: name), responder: responder)

        case .searchLastQueryAgain:
            guard let query = context.lastSearchQuery else {
                addAssistantMessage("No tengo una búsqueda reciente para repetir.")
                return true
            }
            return executeFollowUpAction(.searchGoogle(query: query), responder: responder)

        case .openLastWebsiteAgain:
            guard let urlString = context.lastOpenedWebsiteURL,
                  let url = URL(string: urlString) else {
                addAssistantMessage("No tengo un sitio reciente para volver a abrir.")
                return true
            }
            return executeFollowUpAction(.openWebsite(url: url), responder: responder)

        case .openLastFolderAgain:
            guard let folderPath = context.lastOpenedFolderPath else {
                addAssistantMessage("No tengo una carpeta reciente para volver a abrir.")
                return true
            }
            return executeFollowUpAction(.openFolder(path: folderPath), responder: responder)

        case .openLastAppAgain:
            guard let appName = context.lastOpenedAppName else {
                addAssistantMessage("No tengo una app reciente para volver a abrir.")
                return true
            }
            return executeFollowUpAction(.openApp(name: appName), responder: responder)

        case .askLastThing:
            if let summary = context.lastActionSummary {
                addAssistantMessage("Lo último que tengo en contexto fue: \(summary).")
            } else {
                addAssistantMessage("Todavía no tengo una acción reciente en contexto.")
            }
            return true

        case .unknown:
            return false
        }
    }
    
    @discardableResult
    private func processSingleCommand(
        _ command: String,
        naturalResponder: AssistantNaturalResponder
    ) -> Bool {
        if let identityCommand = identityParser.parse(command) {
            switch identityCommand {
            case .askName:
                addAssistantMessage(naturalResponder.respondToNameQuestion())
                statusMessage = "Respuesta enviada"
                return false

            case .setName(let name):
                let success = identityStore.setNameOnce(name)
                let updatedResponder = AssistantNaturalResponder(
                    style: AssistantResponseStyle(
                        assistantName: identityStore.assistantName,
                        wasInvokedByName: false
                    )
                )

                if success {
                    addAssistantMessage(updatedResponder.respondToNameSetSuccess(name))
                    addSystemLog("Nombre del asistente fijado → \(name)")
                    statusMessage = "Nombre guardado"
                } else {
                    addAssistantMessage(updatedResponder.respondToNameSetRejected(currentName: identityStore.assistantName))
                    addSystemLog("Intento rechazado de cambiar nombre del asistente")
                    statusMessage = "Nombre bloqueado"
                }

                return false
            }
        }

        let socialIntent = socialParser.parse(command)
        if let socialResponse = naturalResponder.respond(to: socialIntent) {
            addAssistantMessage(socialResponse)
            statusMessage = "Respuesta enviada"
            return false
        }

        let knowledgeIntent = knowledgeParser.parse(command)
        if let knowledgeResponse = knowledgeResponse(for: knowledgeIntent, responder: naturalResponder) {
            addAssistantMessage(knowledgeResponse)
            statusMessage = "Respuesta enviada"
            return false
        }

        if handleConversationalFollowUp(command, responder: naturalResponder) {
            return false
        }

        if let advancedCompound = advancedCompoundParser.parse(
            command,
            memoryStore: memoryStore,
            context: conversationContextStore.context
        ) {
            switch advancedCompound {
            case .single(let action):
                addSystemLog("Acción compuesta detectada → \(String(describing: action))")

                if case .runWorkflow(let name) = action {
                    runWorkflow(named: name)
                    return false
                }

                switch validator.validate(action) {
                case .invalid(let message):
                    addSystemLog("Validación fallida → \(message)")
                    addAssistantMessage(message)
                    statusMessage = message
                    return false

                case .warning(let message):
                    pendingConfirmation = PendingConfirmation(
                        action: action,
                        createdAt: Date(),
                        reason: message,
                        workflowContext: nil
                    )

                    addSystemLog("Warning → \(message)")
                    addAssistantMessage("\(message) Escribe CONFIRMAR para continuar o CANCELAR para abortar.")
                    statusMessage = "Esperando confirmación"
                    return false

                case .valid:
                    break
                }

                if action.requiresConfirmation {
                    pendingConfirmation = PendingConfirmation(
                        action: action,
                        createdAt: Date(),
                        reason: action.confirmationMessage,
                        workflowContext: nil
                    )

                    addAssistantMessage(action.confirmationMessage)
                    statusMessage = "Esperando confirmación"
                    return false
                }

                let result = executor.execute(action)

                if result.success {
                    updateConversationContext(for: action)
                }

                addSystemLog(result.technicalMessage)
                addAssistantMessage(naturalResponder.personalizeExecutionMessage(result.userMessage))
                statusMessage = result.userMessage
                refreshSuggestions(after: action, result: result, naturalResponder: naturalResponder)
                return result.success
                
            case .sequence(let actions):
                return executeActionSequence(actions, naturalResponder: naturalResponder)
            }
        }
        let action = parser.parse(command)
        addSystemLog("Acción detectada → \(String(describing: action))")

        if case .runWorkflow(let name) = action {
            runWorkflow(named: name)
            return false
        }

        switch validator.validate(action) {
        case .invalid(let message):
            addSystemLog("Validación fallida → \(message)")
            addAssistantMessage(message)
            statusMessage = message
            return false

        case .warning(let message):
            pendingConfirmation = PendingConfirmation(
                action: action,
                createdAt: Date(),
                reason: message,
                workflowContext: nil
            )

            addSystemLog("Warning → \(message)")
            addAssistantMessage("\(message) Escribe CONFIRMAR para continuar o CANCELAR para abortar.")
            statusMessage = "Esperando confirmación"
            return false

        case .valid:
            break
        }

        if action.requiresConfirmation {
            pendingConfirmation = PendingConfirmation(
                action: action,
                createdAt: Date(),
                reason: action.confirmationMessage,
                workflowContext: nil
            )

            addAssistantMessage(action.confirmationMessage)
            statusMessage = "Esperando confirmación"
            return false
        }

        let result = executor.execute(action)

        if result.success {
            updateConversationContext(for: action)
        }

        addSystemLog(result.technicalMessage)
        addAssistantMessage(naturalResponder.personalizeExecutionMessage(result.userMessage))
        statusMessage = result.userMessage
        return result.success
    }
    
    var executedAtLeastOne = false
    
    @discardableResult
    private func executeActionSequence(
        _ actions: [AssistantAction],
        naturalResponder: AssistantNaturalResponder
    ) -> Bool {
        for action in actions {
            addSystemLog("Acción compuesta → \(String(describing: action))")

            switch validator.validate(action) {
            case .invalid(let message):
                addSystemLog("Validación fallida → \(message)")
                addAssistantMessage(message)
                statusMessage = message
                return false

            case .warning(let message):
                pendingConfirmation = PendingConfirmation(
                    action: action,
                    createdAt: Date(),
                    reason: message,
                    workflowContext: nil
                )
                addSystemLog("Warning en acción compuesta → \(message)")
                addAssistantMessage("\(message) Escribe CONFIRMAR para continuar o CANCELAR para abortar.")
                statusMessage = "Esperando confirmación"
                return false

            case .valid:
                break
            }

            if action.requiresConfirmation {
                pendingConfirmation = PendingConfirmation(
                    action: action,
                    createdAt: Date(),
                    reason: action.confirmationMessage,
                    workflowContext: nil
                )
                addAssistantMessage(action.confirmationMessage)
                statusMessage = "Esperando confirmación"
                return false
            }

            let result = executor.execute(action)
            
            if result.success {
                updateConversationContext(for: action)
                executedAtLeastOne = true
            }

            addSystemLog(result.technicalMessage)
            addAssistantMessage(naturalResponder.personalizeExecutionMessage(result.userMessage))
            statusMessage = result.userMessage

            if !result.success {
                return false
            }
        }
        return executedAtLeastOne
    }
    private func executeFollowUpAction(
        _ action: AssistantAction,
        responder: AssistantNaturalResponder
    ) -> Bool {
        addSystemLog("Follow-up → \(String(describing: action))")

        switch validator.validate(action) {
        case .invalid(let message):
            addSystemLog("Validación fallida → \(message)")
            addAssistantMessage(message)
            statusMessage = message
            return true

        case .warning(let message):
            pendingConfirmation = PendingConfirmation(
                action: action,
                createdAt: Date(),
                reason: message,
                workflowContext: nil
            )
            addAssistantMessage("\(message) Escribe CONFIRMAR para continuar o CANCELAR para abortar.")
            statusMessage = "Esperando confirmación"
            return true

        case .valid:
            break
        }

        if action.requiresConfirmation {
            pendingConfirmation = PendingConfirmation(
                action: action,
                createdAt: Date(),
                reason: action.confirmationMessage,
                workflowContext: nil
            )
            addAssistantMessage(action.confirmationMessage)
            statusMessage = "Esperando confirmación"
            return true
        }

        let result = executor.execute(action)

        if result.success {
            updateConversationContext(for: action)
        }

        addSystemLog(result.technicalMessage)
        addAssistantMessage(responder.personalizeExecutionMessage(result.userMessage))
        statusMessage = result.userMessage
        refreshSuggestions(after: action, result: result, naturalResponder: responder)
        return true
    }
    private func refreshSuggestions(
        after action: AssistantAction,
        result: AssistantExecutionResult,
        naturalResponder: AssistantNaturalResponder
    ) {
        suggestions = suggestionEngine.suggestions(
            for: action,
            result: result,
            context: conversationContextStore.context,
            assistantName: identityStore.assistantName,
            memoryStore: memoryStore,
            workflowStore: workflowStore
        )
    }
    func clearSuggestions() {
        suggestions = []
    }
    func runSuggestedCommand(_ command: String) {
        commandText = command
        runCommand()
    }
    private func normalizedCommandForPatternDetection(_ command: String) -> String {
        command
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
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

        evaluateWorkflowPatternSuggestion()
    }
    private func evaluateWorkflowPatternSuggestion() {
        guard pendingWorkflowSuggestion == nil else { return }

        guard let suggestion = actionPatternDetector.detectSuggestion(from: actionHistory) else {
            return
        }

        let existing = workflowStore.all().contains {
            $0.commands.map { normalizedCommandForPatternDetection($0) } ==
            suggestion.commands.map { normalizedCommandForPatternDetection($0) }
        }

        guard !existing else { return }

        pendingWorkflowSuggestion = suggestion
        addAssistantMessage("Veo que has repetido una secuencia de comandos. ¿Quieres que la guarde como workflow '\(suggestion.suggestedName)'?")
        addSystemLog("Sugerencia automática de workflow → \(suggestion.suggestedName)")
    }
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
    func rebuildInstalledAppsIndex() {
        installedAppsIndex.rebuild()
        addAssistantMessage("Listo, actualicé el índice de apps instaladas.")
        addSystemLog("Índice de apps reconstruido")
        statusMessage = "Índice actualizado"
    }
}
