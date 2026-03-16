//
//  AssistantActionParsing.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

protocol AssistantActionParsing {
    func parse(_ input: String) -> AssistantAction?
}
