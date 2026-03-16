//
//  AssistantChatView.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import SwiftUI

struct AssistantChatView: View {
    @EnvironmentObject private var viewModel: AssistantViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if viewModel.chatMessages.isEmpty {
                            emptyState
                        } else {
                            ForEach(viewModel.chatMessages.reversed()) { message in
                                chatBubble(message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: viewModel.chatMessages.count) { _ in
                    if let last = viewModel.chatMessages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Chat")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text("Habla con el asistente y recibe respuestas naturales")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Todavía no hay mensajes")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text("Prueba con algo como: abre spotify, qué puedes hacer, o ejecuta modo trabajo.")
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

    private func chatBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .bottom) {
            if message.role == .assistant {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.assistantDisplayName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(message.text)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }

                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Tú")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(message.text)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.16))
                        )
                }
            }
        }
    }
}

#Preview {
    let vm = AssistantViewModel()
    vm.chatMessages = [
        ChatMessage(role: .assistant, text: "Hola. Puedo ayudarte con apps, carpetas, memoria y workflows."),
        ChatMessage(role: .user, text: "abre github"),
        ChatMessage(role: .assistant, text: "Listo, intenté abrir GitHub.")
    ]

    return AssistantChatView()
        .environmentObject(vm)
        .frame(width: 620, height: 520)
        .padding()
        .background(Color.black)
}
