//
//  TraceableAssistantActionParsing.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

protocol TraceableAssistantActionParsing: AssistantActionParsing {
    var parserName: String { get }
}
