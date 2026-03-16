//
//  AssistantIdentityStore.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation
internal import Combine

@MainActor
final class AssistantIdentityStore: ObservableObject {
    @Published private(set) var identity = AssistantIdentity()

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folderURL = appSupport.appendingPathComponent("AssistantData", isDirectory: true)

        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        self.fileURL = folderURL.appendingPathComponent("assistant_identity.json")

        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            identity = AssistantIdentity()
            save()
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            identity = try JSONDecoder().decode(AssistantIdentity.self, from: data)
        } catch {
            print("Error cargando identidad:", error)
            identity = AssistantIdentity()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(identity)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error guardando identidad:", error)
        }
    }

    func setNameOnce(_ name: String) -> Bool {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !clean.isEmpty else { return false }
        guard identity.name == nil, identity.isNameLocked == false else { return false }

        identity.name = clean
        identity.isNameLocked = true
        save()
        return true
    }

    var assistantName: String? {
        identity.name
    }

    var hasLockedName: Bool {
        identity.isNameLocked
    }
}
