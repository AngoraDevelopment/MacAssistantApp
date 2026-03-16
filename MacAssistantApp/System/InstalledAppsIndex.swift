//
//  InstalledAppsIndex.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation
internal import Combine

@MainActor
final class InstalledAppsIndex: ObservableObject {
    @Published private(set) var apps: [InstalledAppInfo] = []

    func rebuild() {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser.path

        let searchRoots = [
            "/Applications",
            "\(home)/Applications",
            "/System/Applications"
        ]

        var found: [InstalledAppInfo] = []

        for root in searchRoots {
            let rootURL = URL(fileURLWithPath: root, isDirectory: true)

            guard let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                guard url.pathExtension.lowercased() == "app" else { continue }

                let displayName = url.deletingPathExtension().lastPathComponent
                let normalizedName = AppNameNormalizer.normalize(displayName)
                
                let bundleIdentifier = readBundleIdentifier(from: url)
                
                let info = InstalledAppInfo(
                    displayName: displayName,
                    normalizedName: normalizedName,
                    bundleIdentifier: bundleIdentifier,
                    appURLPath: url.path
                )

                found.append(info)
            }
        }

        // Deduplicar por ruta
        var seenPaths = Set<String>()
        var uniqueApps: [InstalledAppInfo] = []

        for app in found {
            if !seenPaths.contains(app.appURLPath) {
                seenPaths.insert(app.appURLPath)
                uniqueApps.append(app)
            }
        }

        apps = uniqueApps.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
    
    private func readBundleIdentifier(from appURL: URL) -> String? {
        let infoURL = appURL.appendingPathComponent("Contents/Info.plist")

        guard let data = try? Data(contentsOf: infoURL) else {
            return nil
        }

        guard let plist = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            return nil
        }

        return plist["CFBundleIdentifier"] as? String
    }
    
    func app(matching rawName: String) -> InstalledAppInfo? {
        let query = AppNameNormalizer.normalize(rawName)

        guard !query.isEmpty else { return nil }

        // 1. Coincidencia exacta normalizada
        if let exact = apps.first(where: { $0.normalizedName == query }) {
            return exact
        }

        // 2. Coincidencia por contains
        if let contains = apps.first(where: { $0.normalizedName.contains(query) || query.contains($0.normalizedName) }) {
            return contains
        }

        // 3. Coincidencia difusa simple
        let ranked = apps
            .map { app in
                (app: app, score: similarityScore(query, app.normalizedName))
            }
            .sorted { $0.score > $1.score }

        if let best = ranked.first, best.score >= 0.72 {
            return best.app
        }

        return nil
    }

    func suggestions(for rawName: String, limit: Int = 5) -> [InstalledAppInfo] {
        let query = AppNameNormalizer.normalize(rawName)

        guard !query.isEmpty else { return [] }

        return apps
            .map { app in
                (app: app, score: similarityScore(query, app.normalizedName))
            }
            .filter { $0.score >= 0.45 || $0.app.normalizedName.contains(query) || query.contains($0.app.normalizedName) }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map(\.app)
    }

    private func similarityScore(_ lhs: String, _ rhs: String) -> Double {
        if lhs == rhs { return 1.0 }
        if rhs.contains(lhs) || lhs.contains(rhs) { return 0.9 }

        let distance = levenshtein(lhs, rhs)
        let maxLen = max(lhs.count, rhs.count)

        guard maxLen > 0 else { return 0 }
        return 1.0 - (Double(distance) / Double(maxLen))
    }

    private func levenshtein(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)

        let empty = Array(repeating: 0, count: bChars.count + 1)
        var last = Array(0...bChars.count)

        for (i, aChar) in aChars.enumerated() {
            var current = empty
            current[0] = i + 1

            for (j, bChar) in bChars.enumerated() {
                current[j + 1] = aChar == bChar
                    ? last[j]
                    : min(last[j], last[j + 1], current[j]) + 1
            }

            last = current
        }

        return last[bChars.count]
    }
}
