//
//  FileResolver.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct FileResolver {
    let userFilesIndex: UserFilesIndex

    func resolve(_ rawQuery: String) -> IndexedFileInfo? {
        userFilesIndex.file(matching: rawQuery)
    }

    func suggestions(for rawQuery: String) -> [IndexedFileInfo] {
        userFilesIndex.suggestions(for: rawQuery)
    }
}
