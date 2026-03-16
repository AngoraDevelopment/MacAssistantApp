//
//  FileExecutionService.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import AppKit
import Foundation

@MainActor
final class FileExecutionService {
    private let userFilesIndex: UserFilesIndex

    init(userFilesIndex: UserFilesIndex) {
        self.userFilesIndex = userFilesIndex
    }

    func openFile(at path: String) -> AssistantExecutionResult {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "Archivo no existe → \(expandedPath)",
                userMessage: "No pude encontrar ese archivo."
            )
        }

        let opened = NSWorkspace.shared.open(url)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: "Archivo abierto → \(expandedPath)",
            userMessage: opened ? "Listo, abrí \(url.lastPathComponent)." : "No pude abrir ese archivo."
        )
    }

    func findFile(query: String) -> AssistantExecutionResult {
        let resolver = FileResolver(userFilesIndex: userFilesIndex)

        guard let file = resolver.resolve(query) else {
            let suggestions = resolver.suggestions(for: query).map(\.fileName)
            let suffix = suggestions.isEmpty ? "" : " Quizá quisiste decir: \(suggestions.joined(separator: ", "))."

            return AssistantExecutionResult(
                success: false,
                technicalMessage: "Archivo no encontrado → \(query)",
                userMessage: "No encontré un archivo que coincida con \(query).\(suffix)"
            )
        }

        let opened = NSWorkspace.shared.open(file.fileURL)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: "Archivo resuelto y abierto → \(file.filePath)",
            userMessage: opened ? "Listo, abrí \(file.fileName)." : "Encontré \(file.fileName), pero no pude abrirlo."
        )
    }
}
