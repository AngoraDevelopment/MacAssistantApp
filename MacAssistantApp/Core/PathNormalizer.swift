//
//  PathNormalizer.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation

struct PathNormalizer {
    static func normalizeFolderPath(_ raw: String) -> String {
        let lower = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let home = FileManager.default.homeDirectoryForCurrentUser.path

        let aliases: [String: String] = [
            "downloads": "\(home)/Downloads",
            "download": "\(home)/Downloads",
            "descargas": "\(home)/Downloads",
            "carpeta downloads": "\(home)/Downloads",
            "carpeta descargas": "\(home)/Downloads",

            "desktop": "\(home)/Desktop",
            "escritorio": "\(home)/Desktop",
            "mi escritorio": "\(home)/Desktop",

            "documents": "\(home)/Documents",
            "documentos": "\(home)/Documents",
            "mis documentos": "\(home)/Documents",

            "music": "\(home)/Music",
            "musica": "\(home)/Music",

            "pictures": "\(home)/Pictures",
            "imagenes": "\(home)/Pictures",
            "photos": "\(home)/Pictures"
        ]

        if let mapped = aliases[lower] {
            return mapped
        }

        if lower.hasPrefix("~/") {
            return NSString(string: lower).expandingTildeInPath
        }

        if lower.hasPrefix("/") {
            return lower
        }

        return raw
    }
}
