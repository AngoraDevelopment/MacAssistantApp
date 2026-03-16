//
//  AssistantViewModel.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation
import AppKit
internal import Combine

final class AssistantViewModel: ObservableObject {
    @Published var commandText: String = ""
    @Published var history: [String] = []
    @Published var statusMessage: String = "Listo"

    private let parser = CommandParser()
    private let executor = SystemActionExecutor()

    func runCommand() {
        let command = commandText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !command.isEmpty else {
            statusMessage = "Escribe un comando primero"
            return
        }

        history.insert("Tú: \(command)", at: 0)

        let action = parser.parse(command)
        history.insert("Asistente: Acción detectada → \(String(describing: action))", at: 0)

        let result = executor.execute(action)
        history.insert("Asistente: \(result)", at: 0)
        statusMessage = result

        commandText = ""
    }
}
