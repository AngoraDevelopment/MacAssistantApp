//
//  MemoryExecutionService.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct MemoryExecutionService {
    let memoryStore: MemoryStore

    func rememberFolderAlias(alias: String, path: String) -> AssistantExecutionResult {
        memoryStore.rememberFolderAlias(alias: alias, path: path)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias carpeta guardado → \(alias) = \(path)",
            userMessage: "Listo, guardé ese alias de carpeta."
        )
    }

    func rememberAppAlias(alias: String, appName: String) -> AssistantExecutionResult {
        memoryStore.rememberAppAlias(alias: alias, appName: appName)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias app guardado → \(alias) = \(appName)",
            userMessage: "Listo, guardé ese alias de app."
        )
    }

    func rememberWebsiteAlias(alias: String, url: String) -> AssistantExecutionResult {
        memoryStore.rememberWebsiteAlias(alias: alias, url: url)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias sitio guardado → \(alias) = \(url)",
            userMessage: "Listo, guardé ese alias de sitio."
        )
    }

    func forgetFolderAlias(_ alias: String) -> AssistantExecutionResult {
        memoryStore.forgetFolderAlias(alias)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias carpeta eliminado → \(alias)",
            userMessage: "Listo, olvidé ese alias de carpeta."
        )
    }

    func forgetAppAlias(_ alias: String) -> AssistantExecutionResult {
        memoryStore.forgetAppAlias(alias)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Alias app eliminado → \(alias)",
            userMessage: "Listo, olvidé ese alias de app."
        )
    }

    func forgetWebsiteAlias(_ alias: String) -> AssistantExecution
