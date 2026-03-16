//
//  WorkflowView.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/10/26.
//

import SwiftUI

struct WorkflowView: View {
    @EnvironmentObject private var viewModel: AssistantViewModel

    @State private var workflowName: String = ""
    @State private var commandsText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                createWorkflowForm
                
                if viewModel.workflowStore.all().isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(viewModel.workflowStore.all()) { workflow in
                                workflowCard(workflow)
                            }
                        }
                        .padding(.top, 4)

                    }
                }

                footer
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Workflows")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text("Rutinas que ejecutan varios comandos seguidos")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var createWorkflowForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nuevo workflow")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            TextField("Nombre del workflow", text: $workflowName)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .foregroundStyle(.white)
                .font(.system(size: 12, design: .monospaced))

            VStack(alignment: .leading, spacing: 8) {
                Text("Comandos (uno por línea)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))

                TextEditor(text: $commandsText)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            Button {
                saveWorkflow()
            } label: {
                Text("Guardar workflow")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(.white)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Todavía no hay workflows guardados")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text("Ejemplo: modo trabajo, modo terraria, modo stream")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    private var footer: some View {
        HStack {
            Text("Puedes ejecutar un workflow desde aquí o escribiendo: ejecuta nombre")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
        }
    }

    private func workflowCard(_ workflow: AssistantWorkflow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workflow.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    Text("\(workflow.commands.count) comando(s)")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        viewModel.runWorkflowFromUI(name: workflow.name)
                    } label: {
                        Text("Ejecutar")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .foregroundStyle(.white)

                    Button {
                        viewModel.deleteWorkflowFromUI(name: workflow.name)
                    } label: {
                        Text("Eliminar")
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

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(workflow.commands.enumerated()), id: \.offset) { index, command in
                    Text("\(index + 1). \(command)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    private func saveWorkflow() {
        let name = workflowName.trimmingCharacters(in: .whitespacesAndNewlines)
        let commands = commandsText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty, !commands.isEmpty else { return }

        viewModel.addWorkflowFromUI(name: name, commandsText: commands)

        workflowName = ""
        commandsText = ""
    }
}

#Preview {
    let vm = AssistantViewModel()
    vm.workflowStore.addWorkflow(
        name: "modo trabajo",
        commands: [
            "abre xcode",
            "abre discord",
            "abre github"
        ]
    )

    return WorkflowView()
        .environmentObject(vm)
        .frame(width: 420, height: 620)
        .padding()
        .background(Color.black)
}
