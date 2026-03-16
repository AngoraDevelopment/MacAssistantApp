//
//  ActionPlan.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

struct ActionPlan: Equatable {
    let originalInput: String
    let steps: [PlannedAction]

    var isEmpty: Bool {
        steps.isEmpty
    }
}
