import Foundation

struct CommandParser {
    private let classifier = IntentClassifierService()
        private let fallback = RuleBasedCommandParser()
        private let entities = EntityExtractor()
        private let systemParser = SystemCommandParser()

        func parse(_ input: String) -> AssistantAction {
            let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !raw.isEmpty else { return .unknown }

            if let systemAction = systemParser.parse(raw) {
                return systemAction
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
        let prefixes = ["abre ", "abrir ", "open ", "inicia ", "ejecuta ", "lanza "]

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
