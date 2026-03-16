//
//  ChainedCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct ChainedCommandParser {
    func splitCommands(_ input: String) -> [String] {
        let cleaned = input
            .replacingOccurrences(of: " y luego ", with: " | ", options: .caseInsensitive)
            .replacingOccurrences(of: " luego ", with: " | ", options: .caseInsensitive)
            .replacingOccurrences(of: " después ", with: " | ", options: .caseInsensitive)
            .replacingOccurrences(of: " despues ", with: " | ", options: .caseInsensitive)
            .replacingOccurrences(of: " entonces ", with: " | ", options: .caseInsensitive)
            .replacingOccurrences(of: " más tarde ", with: " | ", options: .caseInsensitive)
            .replacingOccurrences(of: " mas tarde ", with: " | ", options: .caseInsensitive)

        return cleaned
            .split(separator: "|")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
