//
//  AppResolver.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct AppResolver {
    let installedAppsIndex: InstalledAppsIndex

    func resolve(_ rawName: String) -> InstalledAppInfo? {
        if let indexed = installedAppsIndex.app(matching: rawName) {
            return indexed
        }

        let normalized = NameNormalizer.normalizeApp(rawName)
        return installedAppsIndex.app(matching: normalized)
    }

    func suggestions(for rawName: String) -> [InstalledAppInfo] {
        installedAppsIndex.suggestions(for: rawName)
    }
}
