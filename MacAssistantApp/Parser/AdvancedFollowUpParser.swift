//
//  AdvancedFollowUpParser.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

enum AdvancedFollowUpIntent {
    case reopenLastEntity
    case closeLastApp
    case createFolderInLastFolder(name: String)
    case searchLastQueryAgain
    case openLastWebsiteAgain
    case openLastFolderAgain
    case openLastAppAgain
    case askLastThing
    case unknown
}

struct AdvancedFollowUpParser {
    func parse(_ input: String) -> AdvancedFollowUpIntent {
        let lower = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let reopenPhrases = [
            "ábrelo",
            "abrelo",
            "ábrela",
            "abrela",
            "abre eso",
            "abre eso otra vez",
            "ábrelo otra vez",
            "abrelo otra vez",
            "ábrela de nuevo",
            "abrela de nuevo"
        ]

        if reopenPhrases.contains(lower) {
            return .reopenLastEntity
        }

        let closePhrases = [
            "ciérrala",
            "cierrala",
            "ciérralo",
            "cierralo",
            "cierra eso",
            "cierra esa app"
        ]

        if closePhrases.contains(lower) {
            return .closeLastApp
        }

        let searchAgainPhrases = [
            "búscalo otra vez",
            "buscalo otra vez",
            "búscalo de nuevo",
            "buscalo de nuevo",
            "vuelve a buscar eso",
            "busca eso otra vez"
        ]

        if searchAgainPhrases.contains(lower) {
            return .searchLastQueryAgain
        }

        let openSiteAgainPhrases = [
            "abre esa página otra vez",
            "abre esa pagina otra vez",
            "abre ese sitio otra vez",
            "vuelve a abrir esa página",
            "vuelve a abrir esa pagina"
        ]

        if openSiteAgainPhrases.contains(lower) {
            return .openLastWebsiteAgain
        }

        let openFolderAgainPhrases = [
            "abre esa carpeta otra vez",
            "vuelve a abrir esa carpeta",
            "ábrela otra vez",
            "abre esa carpeta"
        ]

        if openFolderAgainPhrases.contains(lower) {
            return .openLastFolderAgain
        }

        let openAppAgainPhrases = [
            "abre esa app otra vez",
            "vuelve a abrir esa app",
            "ábrela de nuevo",
            "abre la app otra vez"
        ]

        if openAppAgainPhrases.contains(lower) {
            return .openLastAppAgain
        }

        let askLastThingPhrases = [
            "qué fue lo último que hiciste",
            "que fue lo ultimo que hiciste",
            "qué fue lo último",
            "que fue lo ultimo",
            "qué abriste al final",
            "que abriste al final"
        ]

        if askLastThingPhrases.contains(lower) {
            return .askLastThing
        }

        let createPrefixes = [
            "créala ahí",
            "creala ahí",
            "creala ahi",
            "créala ahi"
        ]

        if createPrefixes.contains(lower) {
            return .createFolderInLastFolder(name: "Nueva carpeta")
        }

        let dynamicPrefixes = [
            "crea una carpeta llamada ",
            "crear una carpeta llamada ",
            "haz una carpeta llamada "
        ]

        for prefix in dynamicPrefixes {
            if lower.hasPrefix(prefix) && (lower.hasSuffix(" ahí") || lower.hasSuffix(" ahi")) {
                var value = String(input.dropFirst(prefix.count))
                value = value.replacingOccurrences(of: " ahí", with: "", options: .caseInsensitive)
                value = value.replacingOccurrences(of: " ahi", with: "", options: .caseInsensitive)
                value = value.trimmingCharacters(in: .whitespacesAndNewlines)

                if !value.isEmpty {
                    return .createFolderInLastFolder(name: value)
                }
            }
        }

        return .unknown
    }
}
