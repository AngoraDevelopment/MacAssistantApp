//
//  AssistantAction.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation

enum AssistantAction: Equatable {
    case searchGoogle(query: String)
    case openWebsite(url: URL)
    case openApp(name: String)

    case openFolder(path: String)
    case createFolder(basePath: String, folderName: String?)
    case quitApp(name: String)
    
    case rememberFolderAlias(alias: String, path: String)
    case rememberAppAlias(alias: String, appName: String)
    case rememberWebsiteAlias(alias: String, url: String)

    case forgetFolderAlias(alias: String)
    case forgetAppAlias(alias: String)
    case forgetWebsiteAlias(alias: String)
    
    case listMemory
    case listFolderAliases
    case listAppAliases
    case listWebsiteAliases
    case clearMemory
    
    case shutdownMac
    case unknown
}

extension AssistantAction {
    var requiresConfirmation: Bool {
        switch self {
        case .shutdownMac,
             .clearMemory,
             .quitApp,
             .forgetFolderAlias,
             .forgetAppAlias,
             .forgetWebsiteAlias:
            return true

        default:
            return false
        }
    }

    var confirmationMessage: String {
        switch self {
        case .shutdownMac:
            return "Vas a apagar la Mac. Escribe CONFIRMAR para continuar."

        case .clearMemory:
            return "Vas a borrar toda la memoria guardada. Escribe CONFIRMAR para continuar."

        case .quitApp(let name):
            return "Vas a cerrar \(name). Escribe CONFIRMAR para continuar."

        case .forgetFolderAlias(let alias),
             .forgetAppAlias(let alias),
             .forgetWebsiteAlias(let alias):
            return "Vas a borrar el alias '\(alias)'. Escribe CONFIRMAR para continuar."

        default:
            return "Esta acción requiere confirmación. Escribe CONFIRMAR para continuar."
        }
    }
}
