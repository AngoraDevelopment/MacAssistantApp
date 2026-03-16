//
//  SuggestionEngine.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct SuggestionEngine {

    func suggestions(
        for action: AssistantAction,
        result: AssistantExecutionResult,
        context: ConversationContext,
        assistantName: String?,
        memoryStore: MemoryStore,
        workflowStore: WorkflowStore
    ) -> [AssistantSuggestion] {

        guard result.success else { return [] }

        switch action {
        case .openFolder(let path):
            return folderSuggestions(path: path, memoryStore: memoryStore)
            
        case .openFile:
            return [
                AssistantSuggestion(
                    title: "Abrir carpeta contenedora",
                    command: "abre esa carpeta",
                    category: .folder
                ),
                AssistantSuggestion(
                    title: "Buscar otro archivo",
                    command: "busca archivo config.json",
                    category: .general
                )
            ]

        case .findFile(let query):
            return [
                AssistantSuggestion(
                    title: "Buscar otra vez",
                    command: "busca \(query)",
                    category: .general
                ),
                AssistantSuggestion(
                    title: "Abrir carpeta proyecto",
                    command: "abre proyecto",
                    category: .folder
                )
            ]
            
        case .createFolder(let basePath, let folderName):
            let finalPath: String
            if let folderName, !folderName.isEmpty {
                finalPath = (basePath as NSString).appendingPathComponent(folderName)
            } else {
                finalPath = basePath
            }
            return createdFolderSuggestions(path: finalPath)

        case .openApp(let name):
            return appSuggestions(appName: name)

        case .openWebsite(let url):
            return websiteSuggestions(url: url)

        case .searchGoogle(let query):
            return googleSearchSuggestions(query: query)

        case .searchInsideWebsite(let site, let query):
            return siteSearchSuggestions(site: site, query: query)

        case .runWorkflow(let name):
            return workflowSuggestions(workflowName: name)

        case .rememberFolderAlias(let alias, _):
            return [
                AssistantSuggestion(
                    title: "Abrir \(alias)",
                    command: "abre \(alias)",
                    category: .memory
                )
            ]

        case .rememberAppAlias(let alias, _):
            return [
                AssistantSuggestion(
                    title: "Abrir \(alias)",
                    command: "abre \(alias)",
                    category: .memory
                )
            ]

        case .rememberWebsiteAlias(let alias, _):
            return [
                AssistantSuggestion(
                    title: "Abrir \(alias)",
                    command: "abre \(alias)",
                    category: .memory
                )
            ]

        default:
            return genericSuggestions(context: context, workflowStore: workflowStore)
        }
    }

    // MARK: - Folder

    private func folderSuggestions(path: String, memoryStore: MemoryStore) -> [AssistantSuggestion] {
        var items: [AssistantSuggestion] = []

        items.append(
            AssistantSuggestion(
                title: "Crear carpeta dentro",
                command: "crea una carpeta llamada NuevaCarpeta ahí",
                category: .folder
            )
        )

        items.append(
            AssistantSuggestion(
                title: "Abrir esa carpeta otra vez",
                command: "abre esa carpeta otra vez",
                category: .folder
            )
        )

        items.append(
            AssistantSuggestion(
                title: "Abrir Xcode",
                command: "abre xcode",
                category: .app
            )
        )

        items.append(
            AssistantSuggestion(
                title: "Buscar algo en Google",
                command: "busca tmodloader wiki en google",
                category: .search
            )
        )

        return unique(items)
    }

    private func createdFolderSuggestions(path: String) -> [AssistantSuggestion] {
        [
            AssistantSuggestion(
                title: "Abrir la carpeta creada",
                command: "abre esa carpeta otra vez",
                category: .folder
            ),
            AssistantSuggestion(
                title: "Crear otra carpeta ahí",
                command: "crea una carpeta llamada Assets ahí",
                category: .folder
            ),
            AssistantSuggestion(
                title: "Abrir Xcode",
                command: "abre xcode",
                category: .app
            )
        ]
    }

    // MARK: - App

    private func appSuggestions(appName: String) -> [AssistantSuggestion] {
        let normalized = appName.lowercased()

        if normalized.contains("spotify") {
            return unique([
                AssistantSuggestion(
                    title: "Cerrar Spotify",
                    command: "ciérrala",
                    category: .app
                ),
                AssistantSuggestion(
                    title: "Abrir YouTube",
                    command: "abre youtube",
                    category: .website
                ),
                AssistantSuggestion(
                    title: "Abrir GitHub",
                    command: "abre github",
                    category: .website
                )
            ])
        }

        if normalized.contains("discord") {
            return unique([
                AssistantSuggestion(
                    title: "Cerrar Discord",
                    command: "ciérrala",
                    category: .app
                ),
                AssistantSuggestion(
                    title: "Abrir GitHub",
                    command: "abre github",
                    category: .website
                ),
                AssistantSuggestion(
                    title: "Abrir proyecto",
                    command: "abre proyecto",
                    category: .folder
                )
            ])
        }

        if normalized.contains("xcode") || normalized.contains("visual studio code") {
            return unique([
                AssistantSuggestion(
                    title: "Abrir proyecto",
                    command: "abre proyecto",
                    category: .folder
                ),
                AssistantSuggestion(
                    title: "Abrir GitHub",
                    command: "abre github",
                    category: .website
                ),
                AssistantSuggestion(
                    title: "Buscar documentación SwiftUI",
                    command: "busca swiftui documentation en google",
                    category: .search
                )
            ])
        }

        return unique([
            AssistantSuggestion(
                title: "Cerrar esa app",
                command: "ciérrala",
                category: .app
            ),
            AssistantSuggestion(
                title: "Abrir GitHub",
                command: "abre github",
                category: .website
            ),
            AssistantSuggestion(
                title: "Abrir proyecto",
                command: "abre proyecto",
                category: .folder
            )
        ])
    }

    // MARK: - Website

    private func websiteSuggestions(url: URL) -> [AssistantSuggestion] {
        let host = url.host?.lowercased() ?? ""

        if host.contains("youtube") {
            return unique([
                AssistantSuggestion(
                    title: "Buscar en YouTube",
                    command: "abre youtube y busca baxbeast",
                    category: .website
                ),
                AssistantSuggestion(
                    title: "Abrir GitHub",
                    command: "abre github",
                    category: .website
                ),
                AssistantSuggestion(
                    title: "Buscar en Google",
                    command: "busca lo mismo en google",
                    category: .search
                )
            ])
        }

        if host.contains("github") {
            return unique([
                AssistantSuggestion(
                    title: "Buscar en GitHub",
                    command: "abre github y busca terraria mods",
                    category: .website
                ),
                AssistantSuggestion(
                    title: "Abrir Discord",
                    command: "abre discord",
                    category: .app
                ),
                AssistantSuggestion(
                    title: "Abrir proyecto",
                    command: "abre proyecto",
                    category: .folder
                )
            ])
        }

        if host.contains("google") {
            return unique([
                AssistantSuggestion(
                    title: "Buscar otra vez",
                    command: "búscalo otra vez",
                    category: .search
                ),
                AssistantSuggestion(
                    title: "Buscar en YouTube",
                    command: "abre youtube y busca tmodloader",
                    category: .website
                ),
                AssistantSuggestion(
                    title: "Buscar en GitHub",
                    command: "abre github y busca terraria mods",
                    category: .website
                )
            ])
        }

        return unique([
            AssistantSuggestion(
                title: "Abrir GitHub",
                command: "abre github",
                category: .website
            ),
            AssistantSuggestion(
                title: "Buscar en Google",
                command: "busca swiftui en google",
                category: .search
            )
        ])
    }

    // MARK: - Search

    private func googleSearchSuggestions(query: String) -> [AssistantSuggestion] {
        [
            AssistantSuggestion(
                title: "Buscar lo mismo en YouTube",
                command: "abre youtube y busca \(query)",
                category: .search
            ),
            AssistantSuggestion(
                title: "Buscar lo mismo en GitHub",
                command: "abre github y busca \(query)",
                category: .search
            ),
            AssistantSuggestion(
                title: "Repetir búsqueda",
                command: "búscalo otra vez",
                category: .search
            )
        ]
    }

    private func siteSearchSuggestions(site: String, query: String) -> [AssistantSuggestion] {
        switch site.lowercased() {
        case "youtube":
            return [
                AssistantSuggestion(
                    title: "Buscar lo mismo en Google",
                    command: "busca \(query) en google",
                    category: .search
                ),
                AssistantSuggestion(
                    title: "Buscar lo mismo en GitHub",
                    command: "abre github y busca \(query)",
                    category: .search
                ),
                AssistantSuggestion(
                    title: "Abrir Spotify",
                    command: "abre spotify",
                    category: .app
                )
            ]

        case "github":
            return [
                AssistantSuggestion(
                    title: "Buscar lo mismo en Google",
                    command: "busca \(query) en google",
                    category: .search
                ),
                AssistantSuggestion(
                    title: "Buscar lo mismo en YouTube",
                    command: "abre youtube y busca \(query)",
                    category: .search
                ),
                AssistantSuggestion(
                    title: "Abrir proyecto",
                    command: "abre proyecto",
                    category: .folder
                )
            ]

        default:
            return [
                AssistantSuggestion(
                    title: "Repetir búsqueda",
                    command: "búscalo otra vez",
                    category: .search
                )
            ]
        }
    }

    // MARK: - Workflow

    private func workflowSuggestions(workflowName: String) -> [AssistantSuggestion] {
        [
            AssistantSuggestion(
                title: "Ejecutarlo otra vez",
                command: "ejecuta \(workflowName)",
                category: .workflow
            ),
            AssistantSuggestion(
                title: "Ver workflows",
                command: "lista workflows",
                category: .workflow
            ),
            AssistantSuggestion(
                title: "Abrir GitHub",
                command: "abre github",
                category: .website
            )
        ]
    }

    // MARK: - Generic

    private func genericSuggestions(
        context: ConversationContext,
        workflowStore: WorkflowStore
    ) -> [AssistantSuggestion] {
        var items: [AssistantSuggestion] = []

        if let folder = context.lastOpenedFolderPath, !folder.isEmpty {
            items.append(
                AssistantSuggestion(
                    title: "Crear carpeta ahí",
                    command: "crea una carpeta llamada NuevaCarpeta ahí",
                    category: .folder
                )
            )
        }

        if let app = context.lastOpenedAppName, !app.isEmpty {
            items.append(
                AssistantSuggestion(
                    title: "Cerrar última app",
                    command: "ciérrala",
                    category: .app
                )
            )
        }

        if let query = context.lastSearchQuery, !query.isEmpty {
            items.append(
                AssistantSuggestion(
                    title: "Buscar otra vez",
                    command: "búscalo otra vez",
                    category: .search
                )
            )
        }

        if let workflow = context.lastWorkflowName, !workflow.isEmpty {
            items.append(
                AssistantSuggestion(
                    title: "Ejecutar último workflow",
                    command: "ejecuta \(workflow)",
                    category: .workflow
                )
            )
        }

        if items.isEmpty {
            items = [
                AssistantSuggestion(
                    title: "Abrir GitHub",
                    command: "abre github",
                    category: .website
                ),
                AssistantSuggestion(
                    title: "Abrir YouTube",
                    command: "abre youtube",
                    category: .website
                ),
                AssistantSuggestion(
                    title: "Buscar en Google",
                    command: "busca swiftui en google",
                    category: .search
                )
            ]
        }

        return unique(items)
    }

    // MARK: - Helpers

    private func unique(_ items: [AssistantSuggestion]) -> [AssistantSuggestion] {
        var seen: Set<String> = []
        var result: [AssistantSuggestion] = []

        for item in items {
            let key = item.command.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                result.append(item)
            }
        }

        return Array(result.prefix(4))
    }
}
