//
//  SystemLogView.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import SwiftUI

struct SystemLogView: View {
    @EnvironmentObject private var viewModel: AssistantViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if viewModel.systemLogs.isEmpty {
                            emptyState
                        } else {
                            ForEach(viewModel.systemLogs.reversed()) { log in
                                logRow(log)
                                    .id(log.id)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: viewModel.systemLogs.count) { _ in
                    if let last = viewModel.systemLogs.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Consola")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text("Registro técnico del sistema y ejecución de comandos")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var emptyState: some View {
        Text("Todavía no hay logs técnicos.")
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.65))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
    }

    private func logRow(_ log: SystemLogEntry) -> some View {
        Text(log.text)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(.white.opacity(0.78))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
    }
}

#Preview {
    let vm = AssistantViewModel()
    vm.systemLogs = [
        SystemLogEntry(text: "Acción detectada → openApp(name: \"Spotify\")"),
        SystemLogEntry(text: "App abierta por bundle id: com.spotify.client")
    ]

    return SystemLogView()
        .environmentObject(vm)
        .frame(width: 500, height: 420)
        .padding()
        .background(Color.black)
}
