//
//  WorkflowStore.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/10/26.
//

import Foundation
internal import Combine

@MainActor
final class WorkflowStore: ObservableObject {
    @Published private(set) var workflows: [AssistantWorkflow] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folderURL = appSupport.appendingPathComponent("AssistantData", isDirectory: true)

        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        self.fileURL = folderURL.appendingPathComponent("workflows.json")

        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            workflows = []
            save()
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            workflows = try JSONDecoder().decode([AssistantWorkflow].self, from: data)
        } catch {
            print("Error cargando workflows: \(error)")
            workflows = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(workflows)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error guardando workflows: \(error)")
        }
    }

    func all() -> [AssistantWorkflow] {
        workflows.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func workflow(named name: String) -> AssistantWorkflow? {
        workflows.first { $0.name.lowercased() == name.lowercased() }
    }

    func workflow(id: UUID) -> AssistantWorkflow? {
        workflows.first { $0.id == id }
    }

    func addWorkflow(name: String, commands: [String]) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCommands = commands
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanName.isEmpty, !cleanCommands.isEmpty else { return }

        if let index = workflows.firstIndex(where: { $0.name.lowercased() == cleanName.lowercased() }) {
            workflows[index].commands = cleanCommands
        } else {
            workflows.append(AssistantWorkflow(name: cleanName, commands: cleanCommands))
        }

        save()
    }

    func updateWorkflow(id: UUID, name: String, commands: [String]) {
        guard let index = workflows.firstIndex(where: { $0.id == id }) else { return }

        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCommands = commands
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanName.isEmpty, !cleanCommands.isEmpty else { return }

        workflows[index].name = cleanName
        workflows[index].commands = cleanCommands
        save()
    }

    func duplicateWorkflow(id: UUID) {
        guard let workflow = workflow(id: id) else { return }

        let baseName = workflow.name + " copia"
        var finalName = baseName
        var counter = 2

        while workflows.contains(where: { $0.name.lowercased() == finalName.lowercased() }) {
            finalName = "\(baseName) \(counter)"
            counter += 1
        }

        let duplicated = AssistantWorkflow(name: finalName, commands: workflow.commands)
        workflows.append(duplicated)
        save()
    }

    func deleteWorkflow(named name: String) {
        workflows.removeAll { $0.name.lowercased() == name.lowercased() }
        save()
    }

    func deleteWorkflow(id: UUID) {
        workflows.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        workflows.removeAll()
        save()
    }
    
    private func defaultWorkflows() -> [AssistantWorkflow] {
        [
            AssistantWorkflow(
                name: "modo trabajo",
                commands: [
                    "abre xcode",
                    "abre discord",
                    "abre github"
                ]
            ),
            AssistantWorkflow(
                name: "modo terraria",
                commands: [
                    "abre proyecto",
                    "abre discord",
                    "buscar tmodloader wiki en google"
                ]
            )
        ]
    }
}
