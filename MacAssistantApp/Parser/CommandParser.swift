import Foundation

struct CommandParser {
    private let classifier = IntentClassifierService()
    private let fallback = RuleBasedCommandParser()
    private let entities = EntityExtractor()
    private let systemParser = SystemCommandParser()
    private let memoryParser = MemoryCommandParser()
    private let memoryStore: MemoryStore
    private let workflowParser = WorkflowCommandParser()
    private let workflowStore: WorkflowStore
    private let fileParser = FileCommandParser()

    init(memoryStore: MemoryStore, workflowStore: WorkflowStore) {
        self.memoryStore = memoryStore
        self.workflowStore = workflowStore
    }

    func parse(_ input: String) -> AssistantAction {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        guard !raw.isEmpty else { return .unknown }
        
        if let fileAction = fileParser.parse(raw) {
            return fileAction
        }
        
        if let workflowAction = workflowParser.parse(raw) {
            return workflowAction
        }
        
        if let memoryAction = memoryParser.parse(raw) {
            return memoryAction
        }

        if let systemAction = systemParser.parse(raw) {
            return systemAction
        }

        if let aliasAction = resolveAliasCommand(raw: raw, lower: lower) {
            return aliasAction
        }

        let prediction = classifier.predictIntent(for: raw)
        let detected = entities.extract(from: raw, intent: prediction.label)

        switch prediction.label {
        case "search_web":
            if let query = detected.searchQuery, !query.isEmpty {
                return .searchGoogle(query: query)
            }
            return fallback.parse(raw)

        case "open_app":
            if let appName = detected.appName, !appName.isEmpty {
                return .openApp(name: appName)
            }
            return fallback.parse(raw)

        case "open_site":
            if let site = detected.websiteName,
               let url = NameNormalizer.normalizeWebsite(site) {
                return .openWebsite(url: url)
            }
            return fallback.parse(raw)

        case "open_folder":
            if let path = detected.folderPath, !path.isEmpty {
                return .openFolder(path: path)
            }
            return fallback.parse(raw)

        case "create_folder":
            if let path = detected.folderPath, !path.isEmpty {
                return .createFolder(basePath: path, folderName: detected.folderName)
            }
            return fallback.parse(raw)

        case "quit_app":
            if let appName = detected.appName, !appName.isEmpty {
                return .quitApp(name: appName)
            }
            return fallback.parse(raw)

        case "shutdown_mac":
            return .shutdownMac

        default:
            return fallback.parse(raw)
        }
    }

    private func resolveAliasCommand(raw: String, lower: String) -> AssistantAction? {
        let prefixes = ["abre ", "abrir ", "open ", "puedes abrir "]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let alias = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let folderPath = memoryStore.folderPath(for: alias) {
                    return .openFolder(path: folderPath)
                }

                if let appName = memoryStore.appName(for: alias) {
                    return .openApp(name: appName)
                }

                if let urlString = memoryStore.websiteURL(for: alias),
                   let url = URL(string: urlString) {
                    return .openWebsite(url: url)
                }
            }
        }

        return nil
    }
}

    private func extractSearchQuery(from raw: String, lower: String) -> String? {
        let phrases = [
            "buscar", "busca", "búscame", "buscame", "necesito buscar",
            "quiero buscar", "quiero encontrar", "encuentra", "investiga",
            "googlea", "en google", "abre google y busca", "abre google para buscar"
        ]

        var cleaned = raw
        for phrase in phrases {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }

        cleaned = cleaned
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")

        return cleaned.isEmpty ? nil : cleaned
    }

    private func extractAppName(from raw: String, lower: String) -> String? {
        let prefixes = ["abre ", "abrir ", "open ", "inicia ", "ejecuta ", "lanza ", "puedes abrir "]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let value = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }
        }

        return nil
    }

    private func extractOpenFolder(from raw: String, lower: String) -> String? {
        let prefixes = [
            "abre la carpeta ",
            "abrir carpeta ",
            "open folder ",
            "abre carpeta ",
            "ve a la carpeta ",
            "quiero abrir la carpeta "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let value = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }
        }

        return nil
    }

    private func extractCreateFolder(from raw: String, lower: String) -> String? {
        let prefixes = [
            "crea una carpeta en ",
            "crear carpeta en ",
            "create folder in ",
            "crea carpeta en ",
            "haz una carpeta en ",
            "quiero crear una carpeta en "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let value = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }
        }

        return nil
    }

    private func extractQuitApp(from raw: String, lower: String) -> String? {
        let prefixes = [
            "cierra ",
            "cerrar ",
            "quit ",
            "close ",
            "quiero cerrar "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let value = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }
        }

        return nil
    }
