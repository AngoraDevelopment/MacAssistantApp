//
//  WorkflowEditorView.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/10/26.
//

import SwiftUI

struct WorkflowEditorView: View {
    @EnvironmentObject private var viewModel: AssistantViewModel

    @State private var selectedWorkflowID: UUID?
    @State private var draftName: String = ""
    @State private var draftCommands: [String] = []
    @State private var newCommandText: String = ""

    var body: some View {
        HStack(spacing: 16) {
            sidebar
            editorPanel
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Workflows")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    createEmptyWorkflow()
                } label: {
                    Text("Nuevo")
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
            }

            Text("Rutinas con varios pasos que el asistente puede ejecutar en orden.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))

            if viewModel.workflowStore.all().isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No hay workflows")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Crea uno nuevo para empezar.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.workflowStore.all()) { workflow in
                            workflowRow(workflow)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Spacer()
        }
        .padding(16)
        .frame(width: 280)
        .background(panelBackground)
        .overlay(panelBorder)
    }

    private var editorPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let workflow = selectedWorkflow {
                editorHeader(workflow)
                nameField
                commandsSection
                addCommandSection
                editorFooter(workflow)
            } else {
                emptyEditor
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(panelBackground)
        .overlay(panelBorder)
    }

    private var selectedWorkflow: AssistantWorkflow? {
        guard let selectedWorkflowID else { return nil }
        return viewModel.workflowStore.workflow(id: selectedWorkflowID)
    }

    private func workflowRow(_ workflow: AssistantWorkflow) -> some View {
        Button {
            loadWorkflow(workflow)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(workflow.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Text("\(workflow.commands.count) comando(s)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selectedWorkflowID == workflow.id ? Color.white.opacity(0.10) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func editorHeader(_ workflow: AssistantWorkflow) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Editor de workflow")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Text("Edita nombre, comandos y orden de ejecución.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.65))
                
                HStack(spacing: 8) {
                    actionButton("Ejecutar") {
                        viewModel.runWorkflowFromUI(name: workflow.name)
                    }

                    actionButton("Duplicar") {
                        viewModel.duplicateWorkflowFromUI(id: workflow.id)
                    }

                    actionButton("Eliminar") {
                        viewModel.deleteWorkflowFromUI(name: workflow.name)
                    }
                }
            }

            Spacer()

            
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nombre")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            TextField("Nombre del workflow", text: $draftName)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(fieldBackground)
                .overlay(fieldBorder)
                .foregroundStyle(.white)
        }
    }

    private var commandsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comandos")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            if draftCommands.isEmpty {
                Text("Todavía no hay comandos.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(draftCommands.enumerated()), id: \.offset) { index, command in
                            commandRow(index: index, command: command)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(minHeight: 180, maxHeight: 340)
            }
        }
    }

    private func commandRow(index: Int, command: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Paso \(index + 1)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                HStack(spacing: 6) {
                    smallIconButton("↑") {
                        moveCommandUp(at: index)
                    }

                    smallIconButton("↓") {
                        moveCommandDown(at: index)
                    }

                    smallIconButton("✕") {
                        removeCommand(at: index)
                    }
                }
            }

            TextField("Comando", text: bindingForCommand(at: index))
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(fieldBackground)
                .overlay(fieldBorder)
                .foregroundStyle(.white)
        }
        .padding(12)
        .background(cardBackground)
    }

    private var addCommandSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Agregar comando")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                TextField("Ejemplo: abre xcode", text: $newCommandText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
                    .foregroundStyle(.white)
                    .onSubmit {
                        addCommand()
                    }

                Button {
                    addCommand()
                } label: {
                    Text("Agregar")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .foregroundStyle(.white)
            }
        }
    }

    private func editorFooter(_ workflow: AssistantWorkflow) -> some View {
        HStack {
            Text("Los comandos se ejecutan en orden, de arriba hacia abajo.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Button {
                saveChanges(for: workflow)
            } label: {
                Text("Guardar cambios")
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
    }

    private var emptyEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Selecciona un workflow")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text("Elige uno de la izquierda o crea uno nuevo.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func loadWorkflow(_ workflow: AssistantWorkflow) {
        selectedWorkflowID = workflow.id
        draftName = workflow.name
        draftCommands = workflow.commands
        newCommandText = ""
    }

    private func createEmptyWorkflow() {
        let baseName = "Nuevo workflow"
        var finalName = baseName
        var counter = 2

        while viewModel.workflowStore.all().contains(where: { $0.name.lowercased() == finalName.lowercased() }) {
            finalName = "\(baseName) \(counter)"
            counter += 1
        }

        viewModel.addWorkflowFromUI(
            name: finalName,
            commandsText: "abre github"
        )

        if let created = viewModel.workflowStore.workflow(named: finalName) {
            loadWorkflow(created)
        }
    }

    private func addCommand() {
        let clean = newCommandText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        draftCommands.append(clean)
        newCommandText = ""
    }

    private func removeCommand(at index: Int) {
        guard draftCommands.indices.contains(index) else { return }
        draftCommands.remove(at: index)
    }

    private func moveCommandUp(at index: Int) {
        guard index > 0, draftCommands.indices.contains(index) else { return }
        draftCommands.swapAt(index, index - 1)
    }

    private func moveCommandDown(at index: Int) {
        guard index < draftCommands.count - 1, draftCommands.indices.contains(index) else { return }
        draftCommands.swapAt(index, index + 1)
    }

    private func bindingForCommand(at index: Int) -> Binding<String> {
        Binding(
            get: {
                guard draftCommands.indices.contains(index) else { return "" }
                return draftCommands[index]
            },
            set: { newValue in
                guard draftCommands.indices.contains(index) else { return }
                draftCommands[index] = newValue
            }
        )
    }

    private func saveChanges(for workflow: AssistantWorkflow) {
        viewModel.updateWorkflowFromUI(
            id: workflow.id,
            name: draftName,
            commands: draftCommands
        )

        if let updated = viewModel.workflowStore.workflow(id: workflow.id) {
            loadWorkflow(updated)
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
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
    }

    private func smallIconButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .frame(width: 28, height: 24)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .foregroundStyle(.white)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.white.opacity(0.06))
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.04))
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.05))
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
    }
}

#Preview {
    let vm = AssistantViewModel()
    /*
     vm.workflowStore.addWorkflow(
         name: "modo trabajo",
         commands: [
             "abre xcode",
             "abre discord",
             "abre github"
         ]
     )
     vm.workflowStore.addWorkflow(
         name: "modo terraria",
         commands: [
             "abre proyecto",
             "abre discord",
             "buscar tmodloader wiki en google"
         ]
     )
     */

    return WorkflowEditorView()
        .environmentObject(vm)
        .frame(width: 1080, height: 720)
        .padding()
        .background(Color.black)
}
