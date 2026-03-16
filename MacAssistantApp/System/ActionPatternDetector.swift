//
//  ActionPatternDetector.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct ActionPatternDetector {

    func detectSuggestion(from history: [ActionHistoryEntry]) -> WorkflowPatternSuggestion? {
        let normalized = history.map(\.normalizedCommand)

        guard normalized.count >= 4 else { return nil }

        for patternLength in stride(from: 4, through: 2, by: -1) {
            guard normalized.count >= patternLength * 2 else { continue }

            let recentPattern = Array(normalized.suffix(patternLength))
            let earlierCommands = Array(normalized.dropLast(patternLength))

            if containsPattern(recentPattern, in: earlierCommands) {
                let originalCommands = Array(history.suffix(patternLength)).map(\.command)
                let name = suggestedWorkflowName(from: recentPattern)

                return WorkflowPatternSuggestion(
                    suggestedName: name,
                    commands: originalCommands
                )
            }
        }

        return nil
    }

    private func containsPattern(_ pattern: [String], in commands: [String]) -> Bool {
        guard !pattern.isEmpty, commands.count >= pattern.count else { return false }

        for start in 0...(commands.count - pattern.count) {
            let slice = Array(commands[start..<(start + pattern.count)])
            if slice == pattern {
                return true
            }
        }

        return false
    }

    private func suggestedWorkflowName(from commands: [String]) -> String {
        let joined = commands.joined(separator: " ")

        if joined.contains("xcode") || joined.contains("visual studio code") || joined.contains("github") {
            return "modo desarrollo"
        }

        if joined.contains("spotify") && joined.contains("youtube") {
            return "modo entretenimiento"
        }

        if joined.contains("discord") && joined.contains("steam") {
            return "modo gaming"
        }

        if joined.contains("obs") || joined.contains("stream") {
            return "modo streaming"
        }

        if joined.contains("proyecto") {
            return "modo proyecto"
        }

        return "workflow sugerido"
    }
}
