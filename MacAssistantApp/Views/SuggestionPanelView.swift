//
//  SuggestionPanelView.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import SwiftUI

struct SuggestionPanelView: View {
    @EnvironmentObject private var viewModel: AssistantViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sugerencias")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Acciones útiles según lo último que hiciste")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                if !viewModel.suggestions.isEmpty {
                    Button {
                        viewModel.clearSuggestions()
                    } label: {
                        Text("Limpiar")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .foregroundStyle(.white)
                }
            }

            if viewModel.suggestions.isEmpty {
                Text("Todavía no hay sugerencias. Ejecuta una acción y te propondré pasos siguientes.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.suggestions) { suggestion in
                        suggestionRow(suggestion)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func suggestionRow(_ suggestion: AssistantSuggestion) -> some View {
        Button {
            viewModel.runSuggestedCommand(suggestion.command)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Text(suggestion.command)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let vm = AssistantViewModel()
    vm.suggestions = [
        AssistantSuggestion(title: "Buscar en YouTube", command: "abre youtube y busca baxbeast", category: .website),
        AssistantSuggestion(title: "Abrir GitHub", command: "abre github", category: .website)
    ]

    return SuggestionPanelView()
        .environmentObject(vm)
        .frame(width: 500, height: 300)
        .padding()
        .background(Color.black)
}
