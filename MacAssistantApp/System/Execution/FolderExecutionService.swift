//
//  FolderExecutionService.swift
//  MacAssistantApp
//
//  Created by Edgardo Ramos on 3/15/26.
//

import AppKit
import Foundation

struct FolderExecutionService {
    func openFolder(_ path: String) -> AssistantExecutionResult {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        guard FileManager.default.fileExists(atPath: expandedPath) else {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "Carpeta no existe → \(expandedPath)",
                userMessage: "No encontré esa carpeta."
            )
        }

        let opened = NSWorkspace.shared.open(url)

        return AssistantExecutionResult(
            success: opened,
            technicalMessage: "Carpeta abierta → \(expandedPath)",
            userMessage: opened
                ? "Listo, abrí la carpeta."
                : "Intenté abrir la carpeta, pero no salió bien."
        )
    }

    func createFolder(basePath: String, folderName: String?) -> AssistantExecutionResult {
        let expandedBasePath = NSString(string: basePath).expandingTildeInPath

        let finalPath: String
        if let folderName, !folderName.isEmpty {
            finalPath = (expandedBasePath as NSString).appendingPathComponent(folderName)
        } else {
            finalPath = expandedBasePath
        }

        do {
            try FileManager.default.createDirectory(
                atPath: finalPath,
                withIntermediateDirectories: true,
                attributes: nil
            )

            return AssistantExecutionResult(
                success: true,
                technicalMessage: "Carpeta creada → \(finalPath)",
                userMessage: "Listo, creé la carpeta."
            )
        } catch {
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "Error creando carpeta → \(error.localizedDescription)",
                userMessage: "No pude crear esa carpeta."
            )
        }
    }
}
