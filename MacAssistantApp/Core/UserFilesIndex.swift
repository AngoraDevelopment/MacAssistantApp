//
//  UserFilesIndex.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation
internal import Combine

@MainActor
final class UserFilesIndex: ObservableObject {
    @Published private(set) var files: [IndexedFileInfo] = []

    func rebuild() {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser.path

        let searchRoots = [
            "\(home)/Desktop",
            "\(home)/Documents",
            "\(home)/Downloads",
            "\(home)/Pictures"
        ]

        var found: [IndexedFileInfo] = []

        for root in searchRoots {
            let rootURL = URL(fileURLWithPath: root, isDirectory: true)

            guard fileManager.fileExists(atPath: root) else { continue }

            guard let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isRegularFileKey, .nameKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])

                guard values?.isRegularFile == true else { continue }
                guard values?.isDirectory != true else { continue }

                let fileName = url.lastPathComponent
                let normalizedName = FileNameNormalizer.normalize(fileName)
                let fileExtension = url.pathExtension.lowercased()
                let parentFolderName = url.deletingLastPathComponent().lastPathComponent

                let fileInfo = IndexedFileInfo(
                    fileName: fileName,
                    normalizedName: normalizedName,
                    filePath: url.path,
                    fileExtension: fileExtension,
                    parentFolderName: parentFolderName
                )

                found.append(fileInfo)
            }
        }

        var seenPaths = Set<String>()
        var uniqueFiles: [IndexedFileInfo] = []

        for file in found {
            if !seenPaths.contains(file.filePath) {
                seenPaths.insert(file.filePath)
                uniqueFiles.append(file)
            }
        }

        files = uniqueFiles.sorted {
            $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending
        }
    }

    func file(matching rawQuery: String) -> IndexedFileInfo? {
        let query = FileNameNormalizer.normalize(rawQuery)

        guard !query.isEmpty else { return nil }

        if let exact = files.first(where: { $0.normalizedName == query }) {
            return exact
        }

        if let exactBase = files.first(where: {
            FileNameNormalizer.normalize(($0.fileName as NSString).deletingPathExtension) == query
        }) {
            return exactBase
        }

        if let contains = files.first(where: {
            $0.normalizedName.contains(query) || query.contains($0.normalizedName)
        }) {
            return contains
        }

        let ranked = files
            .map { file in
                (file: file, score: similarityScore(query, file.normalizedName))
            }
            .sorted { $0.score > $1.score }

        if let best = ranked.first, best.score >= 0.72 {
            return best.file
        }

        return nil
    }

    func suggestions(for rawQuery: String, limit: Int = 6) -> [IndexedFileInfo] {
        let query = FileNameNormalizer.normalize(rawQuery)

        guard !query.isEmpty else { return [] }

        return files
            .map { file in
                (file: file, score: similarityScore(query, file.normalizedName))
            }
            .filter {
                $0.score >= 0.45 ||
                $0.file.normalizedName.contains(query) ||
                query.contains($0.file.normalizedName)
            }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map(\.file)
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
