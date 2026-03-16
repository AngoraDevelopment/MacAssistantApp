//
//  InstalledAppInfo.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

struct InstalledAppInfo: Identifiable, Equatable, Codable {
    let id: UUID
    let displayName: String
    let normalizedName: String
    let bundleIdentifier: String?
    let appURLPath: String

    init(
        id: UUID = UUID(),
        displayName: String,
        normalizedName: String,
        bundleIdentifier: String?,
        appURLPath: String
    ) {
        self.id = id
        self.displayName = displayName
        self.normalizedName = normalizedName
        self.bundleIdentifier = bundleIdentifier
        self.appURLPath = appURLPath
    }

    var appURL: URL {
        URL(fileURLWithPath: appURLPath)
    }
}
