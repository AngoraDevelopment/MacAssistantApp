//
//  RightSidebarView.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import SwiftUI

struct RightSidebarView: View {
    var body: some View {
        TabView {
            AssistantIdentityView()
                .tabItem {
                    Text("Identidad")
            }
            
            MemoryView()
                .tabItem {
                    Text("Memoria")
                }

            WorkflowEditorView()
                .tabItem {
                    Text("Workflows")
                }

            SystemLogView()
                .tabItem {
                    Text("Consola")
                }
        }
    }
}

#Preview {
    RightSidebarView()
        .environmentObject(AssistantViewModel())
        .frame(width: 520, height: 700)
}
