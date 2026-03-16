import Foundation
internal import Combine

import Foundation

struct CommandParser {
    private let parsers: [any TraceableAssistantActionParsing]

    init(
        memoryStore: MemoryStore,
        workflowStore: WorkflowStore
    ) {
        self.parsers = [
            WorkflowCommandParser(),
            FileCommandParser(),
            MemoryCommandParser(memoryStore: memoryStore),
            WebCommandParser(memoryStore: memoryStore),
            FolderCommandParser(memoryStore: memoryStore),
            AppCommandParser(memoryStore: memoryStore),
            MacSystemCommandParser()
        ]
    }

    func parse(_ input: String) -> AssistantAction {
        parseWithTrace(input).action
    }

    func parseWithTrace(_ input: String) -> (action: AssistantAction, trace: ParseTrace?) {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else {
            return (.unknown, nil)
        }

        for parser in parsers {
            if let action = parser.parse(cleaned) {
                return (
                    action,
                    ParseTrace(parserName: parser.parserName, action: action)
                )
            }
        }

        return (.unknown, nil)
    }
}
