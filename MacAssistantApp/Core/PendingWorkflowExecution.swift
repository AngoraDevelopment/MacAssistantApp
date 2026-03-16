//
//  PendingWorkflowExecution.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/10/26.
//

import Foundation

struct PendingWorkflowExecution {
    let workflowName: String
    let commands: [String]
    var currentIndex: Int
}
