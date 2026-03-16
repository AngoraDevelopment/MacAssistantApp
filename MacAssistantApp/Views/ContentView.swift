import SwiftUI
internal import Combine

struct ContentView: View {
    @EnvironmentObject private var viewModel: AssistantViewModel

    var body: some View {
        HStack(spacing: 16) {
            leftPanel
            rightPanel
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.40),
                    Color.black.opacity(0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var leftPanel: some View {
        VStack(spacing: 16) {
            header
            confirmationBanner
            WorkflowPatternSuggestionView()
            AssistantChatView()
            SuggestionPanelView()
            commandBar
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var rightPanel: some View {
        RightSidebarView()
            .frame(minWidth: 540, idealWidth: 600, maxWidth: 700)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.assistantDisplayName)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)

            Text("Angora Dev Studio asistente de programacion y edicion de codigo.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var commandBar: some View {
        HStack(spacing: 12) {
            TextField("Escribe un mensaje o comando...", text: $viewModel.commandText)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .foregroundStyle(.white)
                .onSubmit {
                    viewModel.runCommand()
                }

            Button {
                viewModel.runCommand()
            } label: {
                Text("Enviar")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .foregroundStyle(.white)
        }
    }

    private var footer: some View {
        HStack {
            Text("Estado: \(viewModel.statusMessage)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))

            Spacer()
        }
    }

    private var confirmationBanner: some View {
        Group {
            if let pending = viewModel.pendingConfirmation {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pending.workflowContext == nil ? "Confirmación pendiente" : "Workflow pausado")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)

                    Text(pending.reason)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.82))

                    HStack(spacing: 10) {
                        Button {
                            _ = viewModel.handleManualConfirmation()
                        } label: {
                            Text("Confirmar")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .foregroundStyle(.white)

                        Button {
                            viewModel.cancelPendingConfirmation()
                        } label: {
                            Text("Cancelar")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AssistantViewModel())
        .frame(width: 1380, height: 820)
}
