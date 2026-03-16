//
//  IndexedFileInfo.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct IndexedFileInfo: Identifiable, Equatable, Codable {
    let id: UUID
    let fileName: String
    let normalizedName: String
    let filePath: String
    let fileExtension: String
    let parentFolderName: String

    init(
        id: UUID = UUID(),
        fileName: String,
        normalizedName: String,
        filePath: String,
        fileExtension: String,
        parentFolderName: String
    ) {
        self.id = id
        self.fileName = fileName
        self.normalizedName = normalizedName
        self.filePath = filePath
        self.fileExtension = fileExtension
        self.parentFolderName = parentFolderName
    }

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }
}
