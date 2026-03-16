//
//  MemoryStore.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation
internal import Combine

final class MemoryStore: ObservableObject {
    @Published private(set) var memory = AssistantMemory()

        private let fileURL: URL

        init() {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let folderURL = appSupport.appendingPathComponent("MacAssistant", isDirectory: true)

            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

            self.fileURL = folderURL.appendingPathComponent("memory.json")
            load()
        }

        func load() {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                memory = AssistantMemory()
                return
            }

            do {
                let data = try Data(contentsOf: fileURL)
                memory = try JSONDecoder().decode(AssistantMemory.self, from: data)
            } catch {
                print("Error cargando memoria:", error)
                memory = AssistantMemory()
            }
        }

        func save() {
            do {
                let data = try JSONEncoder().encode(memory)
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("Error guardando memoria:", error)
            }
        }

        func rememberFolderAlias(alias: String, path: String) {
            memory.folderAliases[alias.lowercased()] = path
            save()
        }

        func rememberAppAlias(alias: String, appName: String) {
            memory.appAliases[alias.lowercased()] = appName
            save()
        }

        func rememberWebsiteAlias(alias: String, url: String) {
            memory.websiteAliases[alias.lowercased()] = url
            save()
        }

        func folderPath(for alias: String) -> String? {
            memory.folderAliases[alias.lowercased()]
        }

        func appName(for alias: String) -> String? {
            memory.appAliases[alias.lowercased()]
        }

        func websiteURL(for alias: String) -> String? {
            memory.websiteAliases[alias.lowercased()]
        }

        func forgetFolderAlias(_ alias: String) {
            memory.folderAliases.removeValue(forKey: alias.lowercased())
            save()
        }

        func forgetAppAlias(_ alias: String) {
            memory.appAliases.removeValue(forKey: alias.lowercased())
            save()
        }

        func forgetWebsiteAlias(_ alias: String) {
            memory.websiteAliases.removeValue(forKey: alias.lowercased())
            save()
        }

        func clearAll() {
            memory = AssistantMemory()
            save()
        }

        func allFolderAliases() -> [String: String] {
            memory.folderAliases
        }

        func allAppAliases() -> [String: String] {
            memory.appAliases
        }

        func allWebsiteAliases() -> [String: String] {
            memory.websiteAliases
        }
}

