//
//  AssistantIdentityView.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/11/26.
//

import SwiftUI

struct AssistantIdentityView: View {
    @EnvironmentObject private var viewModel: AssistantViewModel
    @State private var proposedName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            statusCard
            if !viewModel.identityStore.hasLockedName {
                namingForm
            } else {
                lockedInfo
            }
            footer
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
            Text("Identidad")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text("Nombre persistente del asistente y base para futuras interacciones por voz.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Nombre actual")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                statusBadge
            }

            Text(currentNameText)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(statusDescriptionText)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(14)
        .background(cardBackground)
    }

    private var statusBadge: some View {
        Text(viewModel.identityStore.hasLockedName ? "Bloqueado" : "Sin definir")
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(.white)
    }

    private var currentNameText: String {
        viewModel.identityStore.assistantName ?? "Sin nombre"
    }

    private var statusDescriptionText: String {
        if let name = viewModel.identityStore.assistantName {
            return "\(name) quedó guardado de forma permanente. Más adelante podrás usarlo como palabra de activación por voz."
        } else {
            return "Todavía no tiene nombre. Puedes asignarle uno una sola vez y luego quedará fijo."
        }
    }

    private var namingForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Asignar nombre")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            TextField("Escribe el nombre del asistente", text: $proposedName)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(fieldBackground)
                .overlay(fieldBorder)
                .foregroundStyle(.white)
                .onSubmit {
                    lockName()
                }

            Text("El nombre solo se puede asignar una vez.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))

            Button {
                lockName()
            } label: {
                Text("Guardar y bloquear nombre")
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
        .background(cardBackground)
    }

    private var lockedInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nombre fijado")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            Text("Este nombre ya no se puede cambiar desde la app. La idea es mantener una identidad consistente para el asistente.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(14)
        .background(cardBackground)
    }

    private var footer: some View {
        HStack {
            Text("Ejemplos: “cómo te llamas”, “qué eres”, “quién te creó”.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()
        }
    }

    private func lockName() {
        let clean = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        viewModel.setAssistantNameFromUI(clean)
        proposedName = ""
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
}

#Preview {
    let vm = AssistantViewModel()
    return AssistantIdentityView()
        .environmentObject(vm)
        .padding()
        .background(Color.black)
        .frame(width: 500, height: 700)
}
