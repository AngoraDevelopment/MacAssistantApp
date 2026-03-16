//
//  EntityExtractor.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation

struct EntityExtractor {

    func extract(from input: String, intent: String) -> DetectedEntities {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = raw.lowercased()

        switch intent {
        case "search_web":
            return extractSearchEntities(raw: raw, lower: lower)

        case "open_app":
            return extractAppEntities(raw: raw, lower: lower)

        case "open_site":
            return extractWebsiteEntities(raw: raw, lower: lower)

        case "open_folder":
            return extractOpenFolderEntities(raw: raw, lower: lower)

        case "create_folder":
            return extractCreateFolderEntities(raw: raw, lower: lower)

        case "quit_app":
            return extractQuitAppEntities(raw: raw, lower: lower)

        default:
            return DetectedEntities()
        }
    }

    private func extractSearchEntities(raw: String, lower: String) -> DetectedEntities {
        let phrases = [
            "buscar", "busca", "búscame", "buscame",
            "necesito buscar", "quiero buscar", "quiero encontrar",
            "encuentra", "investiga", "googlea",
            "en google", "abre google y busca", "abre google para buscar"
        ]

        var cleaned = raw
        for phrase in phrases {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }

        cleaned = cleaned
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")

        return DetectedEntities(searchQuery: cleaned.isEmpty ? nil : cleaned)
    }

    private func extractAppEntities(raw: String, lower: String) -> DetectedEntities {
        let prefixes = ["abre ", "abrir ", "open ", "inicia ", "ejecuta ", "lanza "]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let value = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                return DetectedEntities(appName: value.isEmpty ? nil : NameNormalizer.normalizeApp(value))
            }
        }

        return DetectedEntities()
    }

    private func extractWebsiteEntities(raw: String, lower: String) -> DetectedEntities {
        let candidates = [
            "youtube", "yt", "github", "google", "gmail", "reddit",
            "stackoverflow", "twitter", "x", "facebook", "netflix",
            "amazon", "wikipedia", "twitch", "linkedin", "duckduckgo",
            "yahoo", "bing", "chatgpt", "notion", "apple developer"
        ]

        for item in candidates {
            if lower.contains(item) {
                return DetectedEntities(websiteName: item)
            }
        }

        return DetectedEntities()
    }

    private func extractOpenFolderEntities(raw: String, lower: String) -> DetectedEntities {

        let triggers = [
            "abre",
            "abrir",
            "open",
            "ve a"
        ]

        guard triggers.contains(where: { lower.contains($0) }) else {
            return DetectedEntities()
        }

        let possibleFolders = [
            "downloads",
            "descargas",
            "desktop",
            "escritorio",
            "documents",
            "documentos",
            "mis documentos",
            "music",
            "pictures"
        ]

        for folder in possibleFolders {

            if lower.contains(folder) {

                return DetectedEntities(
                    folderPath: PathNormalizer.normalizeFolderPath(folder)
                )
            }
        }

        return DetectedEntities()
    }

    private func extractCreateFolderEntities(raw: String, lower: String) -> DetectedEntities {

        let folderKeywords = [
            "llamada",
            "named",
            "con nombre",
            "nombre"
        ]

        let locationKeywords = [
            "en",
            "inside",
            "in"
        ]

        var folderName: String?
        var location: String?

        let words = raw.split(separator: " ")

        for (index, word) in words.enumerated() {

            if folderKeywords.contains(word.lowercased()) {

                let nextIndex = index + 1

                if nextIndex < words.count {
                    folderName = String(words[nextIndex])
                }
            }

            if locationKeywords.contains(word.lowercased()) {

                let nextIndex = index + 1

                if nextIndex < words.count {
                    location = String(words[nextIndex])
                }
            }
        }

        if folderName == nil {
            if lower.contains("carpeta") {

                if let range = raw.range(of: "carpeta") {
                    let after = raw[range.upperBound...]

                    let components = after.split(separator: " ")

                    if let first = components.first {
                        folderName = String(first)
                    }
                }
            }
        }

        return DetectedEntities(
            folderPath: location.map { PathNormalizer.normalizeFolderPath($0) },
            folderName: folderName
        )
    }

    private func extractQuitAppEntities(raw: String, lower: String) -> DetectedEntities {
        let prefixes = ["cierra ", "cerrar ", "quit ", "close "]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) {
                let value = String(raw.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                return DetectedEntities(appName: value.isEmpty ? nil : NameNormalizer.normalizeApp(value))
            }
        }

        return DetectedEntities()
    }
}
