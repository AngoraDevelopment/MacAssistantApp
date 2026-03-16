//
//  ActionPlanning.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import Foundation

protocol ActionPlanning {
    func buildPlan(from input: String) -> ActionPlan?
}
