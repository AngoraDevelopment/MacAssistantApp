//
//  MemoryAliasKind.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation

enum MemoryAliasKind: String, CaseIterable, Identifiable {
    case folder
    case app
    case website

    var id: String { rawValue }

    var title: String {
        switch self {
        case .folder: return "Carpeta"
        case .app: return "App"
        case .website: return "Sitio"
        }
    }
}
