//
//  ConversationFollowUpParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

enum ConversationFollowUpIntent {
    case closeLastApp
    case reopenLastApp
    case createFolderInLastFolder(name: String)
    case askLastSearch
    case askLastApp
    case askLastFolder
    case unknown
}

struct ConversationFollowUpParser {
    func parse(_ input: String) -> ConversationFollowUpIntent {
        let lower = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if ["ciérrala", "cierrala", "cerrar esa app", "cierra esa app"].contains(lower) {
            return .closeLastApp
        }

        if ["ábrela", "abrela", "abre esa app", "abrir esa app"].contains(lower) {
            return .reopenLastApp
        }

        let prefixes = [
            "crea una carpeta llamada ",
            "crear carpeta llamada ",
            "haz una carpeta llamada "
        ]

        for prefix in prefixes {
            if lower.hasPrefix(prefix) && lower.contains(" ahí") {
                let withoutPrefix = String(input.dropFirst(prefix.count))
                let parts = withoutPrefix.components(separatedBy: " ahí")
                let name = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !name.isEmpty {
                    return .createFolderInLastFolder(name: name)
                }
            }
        }

        if ["qué buscaste", "que buscaste", "cuál fue la última búsqueda", "cual fue la ultima busqueda"].contains(lower) {
            return .askLastSearch
        }

        if ["qué app abriste", "que app abriste", "cuál fue la última app", "cual fue la ultima app"].contains(lower) {
            return .askLastApp
        }

        if ["qué carpeta abriste", "que carpeta abriste", "cuál fue la última carpeta", "cual fue la ultima carpeta"].contains(lower) {
            return .askLastFolder
        }

        return .unknown
    }
}
