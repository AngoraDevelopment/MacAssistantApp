import Foundation
import AppKit

@MainActor
final class SystemActionExecutor {
    private let memoryStore: MemoryStore
    private let workflowStore: WorkflowStore
    private let installedAppsIndex: InstalledAppsIndex
    private let userFilesIndex: UserFilesIndex

    init(
        memoryStore: MemoryStore,
        workflowStore: WorkflowStore,
        installedAppsIndex: InstalledAppsIndex,
        userFilesIndex: UserFilesIndex
    ) {
        self.memoryStore = memoryStore
        self.workflowStore = workflowStore
        self.installedAppsIndex = installedAppsIndex
        self.userFilesIndex = userFilesIndex
    }
    
    func execute(_ action: AssistantAction) -> AssistantExecutionResult {
        switch action {
        case .searchGoogle(let query):
            return searchGoogle(query)

        case .openWebsite(let url):
            return openWebsite(url)

        case .openApp(let name):
            return openApp(named: name)
            
        case .searchInsideWebsite(let site, let query):
            return searchInsideWebsite(site: site, query: query)
            
        case .openFolder(let path):
            return openFolder(path)

        case .createFolder(let basePath, let folderName):
            return createFolder(basePath: basePath, folderName: folderName)
            
        case .openFile(let path):
            return openFile(at: path)

        case .findFile(let query):
            return findFile(query: query)
            
        case .quitApp(let name):
            return quitApp(named: name)

        case .rememberFolderAlias(let alias, let path):
            memoryStore.rememberFolderAlias(alias: alias, path: path)
            return AssistantExecutionResultHelper(
                "Recordé la carpeta '\(alias)' → \(path)",
                "Tu carpeta '\(alias)' está ahora asociada con '\(path)",
                true
            )

        case .rememberAppAlias(let alias, let appName):
            memoryStore.rememberAppAlias(alias: alias, appName: appName)
            return AssistantExecutionResultHelper(
                "Recordé la app '\(alias)' → \(appName)",
                "Tu app '\(alias)' está ahora asociada con '\(appName)'",
                true
            )

        case .rememberWebsiteAlias(let alias, let url):
            memoryStore.rememberWebsiteAlias(alias: alias, url: url)
            return AssistantExecutionResultHelper(
                "Recordé el sitio '\(alias)' → \(url)",
                "He guardado el sitio '\(alias)' en mi memoria para ti: '\(url)'",
                true
            )

        case .forgetFolderAlias(let alias):
            memoryStore.forgetFolderAlias(alias)
            memoryStore.forgetAppAlias(alias)
            memoryStore.forgetWebsiteAlias(alias)
            return AssistantExecutionResultHelper(
                "Olvidé '\(alias)'",
                "He sacado '\(alias)' de mi memoria.",
                true
            )

        case .forgetAppAlias(let alias):
            memoryStore.forgetAppAlias(alias)
            return AssistantExecutionResultHelper(
                "Olvidé esta app:'\(alias)'",
                "He sacado esta app de mi memoria: '\(alias)'",
                true
            )

        case .forgetWebsiteAlias(let alias):
            memoryStore.forgetWebsiteAlias(alias)
            return AssistantExecutionResultHelper(
                "Olvidé este sitio:'\(alias)'",
                "He sacado este sitio web de mi memoria: '\(alias)'",
                true
            )
            
        case .clearMemory:
            memoryStore.clearAll()
            return AssistantExecutionResultHelper(
                "Borré toda la memoria guardada.",
                "He borrado toda la memoria de mi asistente.",
                true
            )
            
        case .listMemory:
            return formattedFullMemory()

        case .listFolderAliases:
            return formattedFolderAliases()

        case .listAppAliases:
            return formattedAppAliases()

        case .listWebsiteAliases:
            return formattedWebsiteAliases()

        case .listWorkflows:
            return formattedWorkflows()

        case .createWorkflow(let name, let commands):
            workflowStore.addWorkflow(name: name, commands: commands)
            return AssistantExecutionResultHelper(
                "Guardé el workflow '\(name)' con \(commands.count) comando(s).",
                "He guardado el siguiente workflow: '\(name)': \(commands.joined(separator: ", "))",
                true
            )

        case .deleteWorkflow(let name):
            workflowStore.deleteWorkflow(named: name)
            return AssistantExecutionResultHelper(
                "Borré el workflow '\(name)'.",
                "Borre el siguiente workflow de mi memoria: '\(name)'",
                true
            )

        case .runWorkflow:
            return AssistantExecutionResultHelper(
                "Los workflows se ejecutan desde el ViewModel.",
                "Loas workflows se ejecutan desde el ViewModel.",
                true
            )
            
        case .shutdownMac:
            return shutdownMac()

        case .unknown:
            return AssistantExecutionResultHelper(
                "No entendí la acción.",
                "Lo siento pero no entiendo lo que me dices.",
                false
            )
        }
    }
    
    private func AssistantExecutionResultHelper(_ message: String, _ message2: String , _ shouldFinish: Bool) -> AssistantExecutionResult
    {
        return AssistantExecutionResult(
            success: shouldFinish,
            technicalMessage: message,
            userMessage: message2
        )
    }
    
    private func searchInsideWebsite(site: String, query: String) -> AssistantExecutionResult {
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
                technicalMessage: "No se pudo construir búsqueda dentro de \(site) para query '\(query)'",
                userMessage: "No pude preparar esa búsqueda dentro de \(site)."
            )
        }

        let opened = NSWorkspace.shared.open(url)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: "Búsqueda en sitio → \(site) | query: \(query) | url: \(url.absoluteString)",
            userMessage: opened
                ? "Listo, abrí \(site.capitalized) y lancé la búsqueda de “\(query)”."
                : "Intenté abrir \(site.capitalized) con esa búsqueda, pero no salió bien."
        )
    }
    
    private func formattedFullMemory() -> AssistantExecutionResult {

        let folders = memoryStore.allFolderAliases()
        let apps = memoryStore.allAppAliases()
        let websites = memoryStore.allWebsiteAliases()

        if folders.isEmpty && apps.isEmpty && websites.isEmpty {
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "Memoria consultada → vacía",
                userMessage: "Ahora mismo no tengo nada guardado en memoria."
            )
        }

        var lines: [String] = []
        lines.append("Memoria actual:")

        if !folders.isEmpty {
            lines.append("")
            lines.append("Carpetas:")
            for key in folders.keys.sorted() {
                if let value = folders[key] {
                    lines.append("- \(key) → \(value)")
                }
            }
        }

        if !apps.isEmpty {
            lines.append("")
            lines.append("Apps:")
            for key in apps.keys.sorted() {
                if let value = apps[key] {
                    lines.append("- \(key) → \(value)")
                }
            }
        }

        if !websites.isEmpty {
            lines.append("")
            lines.append("Sitios:")
            for key in websites.keys.sorted() {
                if let value = websites[key] {
                    lines.append("- \(key) → \(value)")
                }
            }
        }

        let formatted = lines.joined(separator: "\n")

        return AssistantExecutionResult(
            success: true,
            technicalMessage: formatted,
            userMessage: "Esto es lo que recuerdo ahora mismo:\n\n\(formatted)"
        )
    }

    private func formattedFolderAliases() -> AssistantExecutionResult {
        let folders = memoryStore.allFolderAliases()

        guard !folders.isEmpty else {
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "Memoria consultada → vacía",
                userMessage: "Ahora mismo no tengo carpetas guardadas en mi memoria."
            )
        }

        var lines = ["Carpetas guardadas:"]
        for key in folders.keys.sorted() {
            if let value = folders[key] {
                lines.append("- \(key) → \(value)")
            }
        }
        
        let formatted = lines.joined(separator: "\n")

        return AssistantExecutionResult(
            success: true,
            technicalMessage: formatted,
            userMessage: "Esto es lo que recuerdo ahora mismo:\n\n\(formatted)"
        )
    }

    private func formattedAppAliases() -> AssistantExecutionResult {
        let apps = memoryStore.allAppAliases()

        guard !apps.isEmpty else {
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "Memoria consultada → vacía",
                userMessage: "Ahora mismo no tengo apps guardadas en mi memoria."
            )
        }

        var lines = ["Apps guardadas:"]
        for key in apps.keys.sorted() {
            if let value = apps[key] {
                lines.append("- \(key) → \(value)")
            }
        }
        
        let formatted = lines.joined(separator: "\n")

        return AssistantExecutionResult(
            success: true,
            technicalMessage: formatted,
            userMessage: "Esto es lo que recuerdo ahora mismo:\n\n\(formatted)"
        )
    }

    private func formattedWebsiteAliases() -> AssistantExecutionResult {
        let websites = memoryStore.allWebsiteAliases()

        guard !websites.isEmpty else {
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "Memoria consultada → vacía",
                userMessage: "Ahora mismo no tengo sitios guardadas en mi memoria."
            )
        }

        var lines = ["Sitios guardados:"]
        for key in websites.keys.sorted() {
            if let value = websites[key] {
                lines.append("- \(key) → \(value)")
            }
        }
        
        let formatted = lines.joined(separator: "\n")

        return AssistantExecutionResult(
            success: true,
            technicalMessage: formatted,
            userMessage: "Esto es lo que recuerdo ahora mismo:\n\n\(formatted)"
        )
    }

    private func searchGoogle(_ query: String) -> AssistantExecutionResult {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://www.google.com/search?q=\(encoded)") else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "No pude construir la busqueda",
                userMessage: "No pude encontrar la búsqueda solicitada."
            )
        }

        NSWorkspace.shared.open(url)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Busqué en Google: \(query)",
            userMessage: "Busqué en Google: \(query)"
        )
    }

    private func openWebsite(_ url: URL) -> AssistantExecutionResult {
        NSWorkspace.shared.open(url)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Abrí el sitio: \(url.absoluteString)",
            userMessage: "Abrí el sitio: \(url.absoluteString)"
        )
    }
    
    private func openApp(named name: String) -> AssistantExecutionResult {
        let resolver = AppResolver(installedAppsIndex: installedAppsIndex)

        guard let app = resolver.resolve(name) else {
            let suggestions = resolver.suggestions(for: name).map(\.displayName)

            let suggestionText: String
            if suggestions.isEmpty {
                suggestionText = ""
            } else {
                suggestionText = " Posibles coincidencias: " + suggestions.joined(separator: ", ") + "."
            }

            return AssistantExecutionResult(
                success: false,
                technicalMessage: "No se encontró app para '\(name)'",
                userMessage: "No pude encontrar una app llamada \(name).\(suggestionText)"
            )
        }

        let workspace = NSWorkspace.shared
        let config = NSWorkspace.OpenConfiguration()

        workspace.openApplication(at: app.appURL, configuration: config) { runningApp, error in
            if let error {
                print("Error abriendo \(app.displayName):", error.localizedDescription)
                return
            }

            guard let runningApp else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                _ = runningApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            }
        }

        return AssistantExecutionResult(
            success: true,
            technicalMessage: "App abierta desde índice → \(app.displayName) | path: \(app.appURLPath)",
            userMessage: "Listo, intenté abrir \(app.displayName)."
        )
    }

    private func bundleIdentifier(for appName: String) -> String? {
        switch appName.lowercased() {
        case "safari":
            return "com.apple.Safari"
        case "xcode":
            return "com.apple.dt.Xcode"
        case "finder":
            return "com.apple.finder"
        case "terminal":
            return "com.apple.Terminal"
        case "google chrome":
            return "com.google.Chrome"
        case "discord":
            return "com.hnc.Discord"
        case "steam":
            return "com.valvesoftware.steam"
        case "spotify":
            return "com.spotify.client"
        default:
            return nil
        }
    }
    
    private func openFolder(_ path: String) -> AssistantExecutionResult {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "La carpeta no existe: \(expandedPath)",
                userMessage: "La carpeta que quieres abrir no existe."
            )
            //return "La carpeta no existe: \(expandedPath)"
        }

        NSWorkspace.shared.open(url)
        return AssistantExecutionResult(
            success: true,
            technicalMessage: "Abrí la carpeta: \(expandedPath)",
            userMessage: "Listo he podido abrir tu carpeta."
        )
    }

    private func createFolder(basePath: String, folderName: String?) -> AssistantExecutionResult {
        let expandedBasePath = NSString(string: basePath).expandingTildeInPath

        let finalPath: String
        if let folderName, !folderName.isEmpty {
            finalPath = (expandedBasePath as NSString).appendingPathComponent(folderName)
        } else {
            finalPath = expandedBasePath
        }

        do {
            try FileManager.default.createDirectory(
                atPath: finalPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "Carpeta creada: \(finalPath)",
                userMessage: "He creado tu carpeta con éxito."
            )
            //return "Carpeta creada: \(finalPath)"
        } catch {
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "No pude crear la carpeta: \(error.localizedDescription)",
                userMessage: "Lo siento no pude crear la carpeta. Intenta de nuevo."
            )
        }
    }

    private func quitApp(named name: String) -> AssistantExecutionResult {
        let normalized = NameNormalizer.normalizeApp(name)
        let runningApps = NSWorkspace.shared.runningApplications

        guard let app = runningApps.first(where: {
            $0.localizedName?.lowercased() == normalized.lowercased()
        }) else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "La app \(normalized) no está abierta.",
                userMessage: "La app \(normalized) no está abierta."
            )
        }

        let ok = app.terminate()
        return AssistantExecutionResult(
            success: false,
            technicalMessage: "La app \(normalized) ha sido cerrada.",
            userMessage: "Listo tu app \(normalized) ha sido cerrada."
        )
    }
    
    private func formattedWorkflows() -> AssistantExecutionResult {
        let workflows = workflowStore.all()

        guard !workflows.isEmpty else {
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "Memoria consultada → vacía",
                userMessage: "Ahora mismo no tengo workflows guardadas en mi memoria."
            )
        }

        var lines: [String] = ["Workflows guardados:"]

        for workflow in workflows {
            lines.append("- \(workflow.name) (\(workflow.commands.count) comandos)")
        }

        let formatted = lines.joined(separator: "\n")

        return AssistantExecutionResult(
            success: true,
            technicalMessage: formatted,
            userMessage: "Esto es lo que recuerdo ahora mismo:\n\n\(formatted)"
        )
    }
    
    private func shutdownMac() -> AssistantExecutionResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to shut down"]
        
        do {
            try process.run()
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "Intenté apagar la Mac.",
                userMessage: "Voy a intentar apagar la Mac por ti.")
        } catch {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "No pude apagar la Mac: \(error.localizedDescription)",
                userMessage: "Lo siento pero no pude apagar la Mac. Intenta de nuevo."
            )
        }
    }
    private func openFile(at path: String) -> AssistantExecutionResult {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "Archivo no existe → \(expandedPath)",
                userMessage: "No pude encontrar ese archivo."
            )
        }

        let opened = NSWorkspace.shared.open(url)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: "Archivo abierto → \(expandedPath)",
            userMessage: opened
                ? "Listo, abrí el archivo \(url.lastPathComponent)."
                : "Intenté abrir el archivo, pero no salió bien."
        )
    }

    private func findFile(query: String) -> AssistantExecutionResult {
        let resolver = FileResolver(userFilesIndex: userFilesIndex)

        guard let file = resolver.resolve(query) else {
            let suggestions = resolver.suggestions(for: query).map(\.fileName)

            let suggestionText: String
            if suggestions.isEmpty {
                suggestionText = ""
            } else {
                suggestionText = " Quizá quisiste decir: " + suggestions.joined(separator: ", ") + "."
            }

            return AssistantExecutionResult(
                success: false,
                technicalMessage: "Archivo no encontrado para query '\(query)'",
                userMessage: "No encontré un archivo que coincida con \(query).\(suggestionText)"
            )
        }

        let opened = NSWorkspace.shared.open(file.fileURL)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: "Archivo resuelto y abierto → \(file.filePath)",
            userMessage: opened
                ? "Listo, abrí \(file.fileName)."
                : "Encontré \(file.fileName), pero no pude abrirlo."
        )
    }
}
