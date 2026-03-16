//
//  FileExecutionService.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import AppKit
import Foundation

struct FileExecutionService {
    let userFilesIndex: UserFilesIndex

    func openFile(at path: String) -> AssistantExecutionResult {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "Archivo no existe → \(expandedPath)",
                userMessage: "No encontré ese archivo."
            )
        }

        let opened = NSWorkspace.shared.open(url)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: "Archivo abierto → \(expandedPath)",
            userMessage: opened
                ? "Listo, abrí el archivo \(url.lastPathComponent)."
                : "Intenté abrir el archivo, pero no salió bien."
        )
    }

    func findFile(query: String) -> AssistantExecutionResult {
        let resolver = FileResolver(userFilesIndex: userFilesIndex)

        guard let file = resolver.resolve(query) else {
            let suggestions = resolver.suggestions(for: query).map(\.fileName)
            let suggestionText = suggestions.isEmpty
                ? ""
                : " Quizá quisiste decir: " + suggestions.joined(separator: ", ") + "."

            return AssistantExecutionResult(
                success: false,
                technicalMessage: "Archivo no encontrado para '\(query)'",
                userMessage: "No encontré un archivo que coincida con \(query).\(suggestionText)"
            )
        }

        let opened = NSWorkspace.shared.open(file.fileURL)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: "Archivo resuelto y abierto → \(file.filePath)",
            userMessage: opened
                ? "Listo, abrí \(file.fileName)."
                : "Encontré \(file.fileName), pero no pude abrirlo."
        )
    }
}
