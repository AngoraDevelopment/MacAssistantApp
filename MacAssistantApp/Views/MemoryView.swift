//
//  MemoryView.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/9/26.
//

import SwiftUI

struct MemoryView: View {
    @EnvironmentObject private var viewModel: AssistantViewModel

    @State private var selectedKind: MemoryAliasKind = .folder
    @State private var aliasText: String = ""
    @State private var valueText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            createAliasForm

            if isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if !viewModel.memoryStore.memory.folderAliases.isEmpty {
                            aliasSection(
                                title: "Carpetas",
                                subtitle: "Rutas y carpetas favoritas",
                                items: viewModel.memoryStore.memory.folderAliases,
                                kind: .folder
                            )
                        }

                        if !viewModel.memoryStore.memory.appAliases.isEmpty {
                            aliasSection(
                                title: "Apps",
                                subtitle: "Aplicaciones guardadas por alias",
                                items: viewModel.memoryStore.memory.appAliases,
                                kind: .app
                            )
                        }

                        if !viewModel.memoryStore.memory.websiteAliases.isEmpty {
                            aliasSection(
                                title: "Sitios",
                                subtitle: "URLs y páginas frecuentes",
                                items: viewModel.memoryStore.memory.websiteAliases,
                                kind: .website
                            )
                        }
                    }
                    .padding(.top, 4)
                }
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

    private var isEmpty: Bool {
        viewModel.memoryStore.memory.folderAliases.isEmpty &&
        viewModel.memoryStore.memory.appAliases.isEmpty &&
        viewModel.memoryStore.memory.websiteAliases.isEmpty
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Memoria")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Text("Guarda aliases de carpetas, apps y sitios para reutilizarlos por nombre.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            Button(role: .destructive) {
                viewModel.clearAllMemoryFromUI()
            } label: {
                Text("Borrar todo")
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
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(.white)
        }
    }

    private var createAliasForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nuevo alias")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            Picker("Tipo", selection: $selectedKind) {
                ForEach(MemoryAliasKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 10) {
                TextField("Alias", text: $aliasText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
                    .foregroundStyle(.white)

                TextField(valuePlaceholder, text: $valueText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
                    .foregroundStyle(.white)
                    .onSubmit {
                        saveAlias()
                    }
            }

            Button {
                saveAlias()
            } label: {
                Text("Guardar alias")
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

    private var valuePlaceholder: String {
        switch selectedKind {
        case .folder:
            return "Ruta, por ejemplo ~/Desktop/ProyectoIA"
        case .app:
            return "Nombre de la app, por ejemplo Spotify"
        case .website:
            return "URL, por ejemplo https://github.com"
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Todavía no hay memoria guardada")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text("Ejemplo: guarda el alias 'proyecto' y luego usa 'abre proyecto'.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground)
    }

    private var footer: some View {
        HStack {
            Text("Tip: también puedes guardar aliases escribiendo comandos como “recuerda que proyecto = ~/Desktop/ProyectoIA”.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()
        }
    }

    private func aliasSection(title: String, subtitle: String, items: [String: String], kind: MemoryAliasKind) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.58))
            }

            ForEach(items.keys.sorted(), id: \.self) { key in
                if let value = items[key] {
                    aliasRow(alias: key, value: value, kind: kind)
                }
            }
        }
    }

    private func aliasRow(alias: String, value: String, kind: MemoryAliasKind) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(alias)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Text(value)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.68))
                    .textSelection(.enabled)
            }

            Spacer()

            Button {
                viewModel.deleteMemoryAlias(alias: alias, kind: kind)
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
        .padding(12)
        .background(cardBackground)
    }

    private func saveAlias() {
        let cleanAlias = aliasText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanValue = valueText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanAlias.isEmpty, !cleanValue.isEmpty else { return }

        viewModel.addMemoryAliasFromUI(
            alias: cleanAlias,
            value: cleanValue,
            kind: selectedKind
        )

        aliasText = ""
        valueText = ""
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
    //vm.memoryStore.rememberFolderAlias(alias: "proyecto", path: "~/Desktop/ProyectoIA")
    //vm.memoryStore.rememberAppAlias(alias: "musica", appName: "Spotify")
    //vm.memoryStore.rememberWebsiteAlias(alias: "repo", url: "https://github.com")

    return MemoryView()
        .environmentObject(vm)
        .frame(width: 500, height: 700)
        .padding()
        .background(Color.black)
}
