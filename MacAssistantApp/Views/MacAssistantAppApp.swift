//
//  MacAssistantAppApp.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import SwiftUI

@main
struct MacAssistantApp: App {
    @StateObject private var viewModel = AssistantViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 720, minHeight: 480)
        }
        .windowResizability(.contentSize)
    }
}
