//
//  WebExecutionService.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import AppKit
import Foundation

struct WebExecutionService {
    func searchGoogle(_ query: String) -> AssistantExecutionResult {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        guard let url = URL(string: "https://www.google.com/search?q=\(encoded)") else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "No se pudo construir URL de Google para query '\(query)'",
                userMessage: "No pude construir esa búsqueda en Google."
            )
        }

        return openURL(
            url,
            technical: "Búsqueda Google → \(query)",
            user: "Listo, busqué “\(query)” en Google."
        )
    }

    func openWebsite(_ url: URL) -> AssistantExecutionResult {
        openURL(
            url,
            technical: "Sitio abierto → \(url.absoluteString)",
            user: "Listo, abrí \(url.absoluteString)."
        )
    }

    func searchInsideWebsite(site: String, query: String) -> AssistantExecutionResult {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString: String?

        switch site.lowercased() {
        case "youtube":
            urlString = "https://www.youtube.com/results?search_query=\(encoded)"
        case "google":
            urlString = "https://www.google.com/search?q=\(encoded)"
        case "github":
            urlString = "https://github.com/search?q=\(encoded)"
        default:
            urlString = nil
        }

        guard let urlString, let url = URL(string: urlString) else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "No se pudo construir búsqueda dentro de \(site) para '\(query)'",
                userMessage: "No pude preparar esa búsqueda dentro de \(site)."
            )
        }

        return openURL(
            url,
            technical: "Búsqueda dentro de sitio → \(site) | \(query)",
            user: "Listo, abrí \(site.capitalized) y lancé la búsqueda de “\(query)”."
        )
    }

    private func openURL(
        _ url: URL,
        technical: String,
        user: String
    ) -> AssistantExecutionResult {
        let opened = NSWorkspace.shared.open(url)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: technical,
            userMessage: opened ? user : "Intenté abrir el enlace, pero no salió bien."
        )
    }
}
