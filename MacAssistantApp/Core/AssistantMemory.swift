//
//  AssistantMemory.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import Foundation

struct AssistantMemory: Codable {
    var folderAliases: [String: String] = [:]
    var appAliases: [String: String] = [:]
    var websiteAliases: [String: String] = [:]
}
