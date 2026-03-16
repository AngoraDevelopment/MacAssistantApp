//
//  CompoundParsedCommand.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import Foundation

enum CompoundParsedCommand {
    case single(AssistantAction)
    case sequence([AssistantAction])
}
