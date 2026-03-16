//
//  ValidationResult.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/10/26.
//

import Foundation

enum ValidationResult: Equatable {
    case valid
    case warning(message: String)
    case invalid(message: String)
}
