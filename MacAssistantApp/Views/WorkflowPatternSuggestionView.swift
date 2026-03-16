//
//  WorkflowPatternSuggestionView.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import SwiftUI
internal import Combine

struct WorkflowPatternSuggestionView: View {
    @EnvironmentObject private var viewModel: AssistantViewModel

    var body: some View {
        Group {
            if let suggestion = viewModel.pendingWorkflowSuggestion {
                content(for: suggestion)
            }
        }
    }

    @ViewBuilder
    private func content(for suggestion: WorkflowPatternSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            suggestionDetails(for: suggestion)
            actionButtons
        }
        .padding(16)
        .background(containerBackground)
        .overlay(containerBorder)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workflow sugerido")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                Text("Detecté una secuencia repetida que podrías guardar como rutina.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func suggestionDetails(for suggestion: WorkflowPatternSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nombre sugerido: \(suggestion.suggestedName)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            commandList(for: suggestion)
        }
        .padding(12)
        .background(cardBackground)
    }

    private func commandList(for suggestion: WorkflowPatternSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(suggestion.commands.enumerated()), id: \.offset) { index, command in
                Text("\(index + 1). \(command)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.acceptPendingWorkflowSuggestion()
            } label: {
                Text("Guardar workflow")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .background(primaryButtonBackground)
            .overlay(buttonBorder)
            .foregroundStyle(.white)

            Button {
                viewModel.rejectPendingWorkflowSuggestion()
            } label: {
                Text("No ahora")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .background(secondaryButtonBackground)
            .overlay(buttonBorder)
            .foregroundStyle(.white)
        }
    }

    private var containerBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.05))
    }

    private var containerBorder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.04))
    }

    private var primaryButtonBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.white.opacity(0.10))
    }

    private var secondaryButtonBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.white.opacity(0.06))
    }

    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
    }
}

#Preview {
    let vm = AssistantViewModel()
    vm.pendingWorkflowSuggestion = WorkflowPatternSuggestion(
        suggestedName: "modo desarrollo",
        commands: [
            "abre xcode",
            "abre github",
            "abre discord"
        ]
    )

    return WorkflowPatternSuggestionView()
        .environmentObject(vm)
        .frame(width: 560, height: 280)
        .padding()
        .background(Color.black)
}
