//
//  WebExecutionService.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import AppKit
import Foundation

@MainActor
final class WebExecutionService {
    func openWebsite(_ url: URL) -> AssistantExecutionResult {
        let opened = NSWorkspace.shared.open(url)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: "Sitio abierto → \(url.absoluteString)",
            userMessage: opened ? "Listo, abrí ese sitio." : "No pude abrir ese sitio."
        )
    }

    func searchGoogle(_ query: String) -> AssistantExecutionResult {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://www.google.com/search?q=\(encoded)") else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "No se pudo construir URL de búsqueda Google",
                userMessage: "No pude preparar esa búsqueda."
            )
        }

        return openWebsite(url)
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
                technicalMessage: "No se pudo construir búsqueda en sitio → \(site)",
                userMessage: "No pude preparar esa búsqueda en \(site)."
            )
        }

        let opened = NSWorkspace.shared.open(url)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: "Búsqueda en sitio → \(site) | \(query) | \(url.absoluteString)",
            userMessage: opened ? "Listo, abrí \(site.capitalized) con esa búsqueda." : "No pude abrir \(site.capitalized) con esa búsqueda."
        )
    }
}
