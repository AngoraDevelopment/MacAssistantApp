//
//  SystemCommandParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation

struct SystemCommandParser {
    private let classifier = IntentClassifierService()
    private let entities = EntityExtractor()
    
    func parse(_ input: String) -> AssistantAction? {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()
        let prediction = classifier.predictIntent(for: raw)
        let detected = entities.extract(from: raw, intent: prediction.label)
        
        if let folder = extractOpenFolder(from: raw, lower: lower) {
            return .openFolder(path: PathNormalizer.normalizeFolderPath(folder))
        }

        if let path = detected.folderPath, !path.isEmpty {
            return .createFolder(basePath: path, folderName: detected.folderName)
        }

        if let app = extractQuitApp(from: raw, lower: lower) {
            return .quitApp(name: app)
        }

        if lower == "apaga la mac" || lower == "apagar mac" || lower == "shut down mac" {
            return .shutdownMac
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
            "close "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                return String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return nil
    }
}
