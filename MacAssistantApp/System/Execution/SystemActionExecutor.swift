import Foundation
import AppKit

@MainActor
final class SystemActionExecutor {
    private let appService: AppExecutionService
    private let fileService: FileExecutionService
    private let folderService: FolderExecutionService
    private let webService: WebExecutionService
    private let memoryService: MemoryExecutionService
    private let workflowService: WorkflowExecutionService

    init(
        appService: AppExecutionService,
        fileService: FileExecutionService,
        folderService: FolderExecutionService,
        webService: WebExecutionService,
        memoryService: MemoryExecutionService,
        workflowService: WorkflowExecutionService
    ) {
        self.appService = appService
        self.fileService = fileService
        self.folderService = folderService
        self.webService = webService
        self.memoryService = memoryService
        self.workflowService = workflowService
    }

    func execute(_ action: AssistantAction) -> AssistantExecutionResult {
        switch action {
        case .openApp(let name):
            return appService.openApp(named: name)

        case .quitApp(let name):
            return appService.quitApp(named: name)

        case .openFile(let path):
            return fileService.openFile(at: path)

        case .findFile(let query):
            return fileService.findFile(query: query)

        case .openFolder(let path):
            return folderService.openFolder(path)

        case .createFolder(let basePath, let folderName):
            return folderService.createFolder(basePath: basePath, folderName: folderName)

        case .openWebsite(let url):
            return webService.openWebsite(url)

        case .searchGoogle(let query):
            return webService.searchGoogle(query)

        case .searchInsideWebsite(let site, let query):
            return webService.searchInsideWebsite(site: site, query: query)

        case .rememberFolderAlias(let alias, let path):
            return memoryService.rememberFolderAlias(alias: alias, path: path)

        case .rememberAppAlias(let alias, let appName):
            return memoryService.rememberAppAlias(alias: alias, appName: appName)

        case .rememberWebsiteAlias(let alias, let url):
            return memoryService.rememberWebsiteAlias(alias: alias, url: url)

        case .forgetFolderAlias(let alias):
            return memoryService.forgetFolderAlias(alias)

        case .forgetAppAlias(let alias):
            return memoryService.forgetAppAlias(alias)

        case .forgetWebsiteAlias(let alias):
            return memoryService.forgetWebsiteAlias(alias)

        case .listMemory:
            return memoryService.listMemory()

        case .listFolderAliases:
            return memoryService.listFolderAliases()

        case .listAppAliases:
            return memoryService.listAppAliases()

        case .listWebsiteAliases:
            return memoryService.listWebsiteAliases()

        case .clearMemory:
            return memoryService.clearMemory()

        case .listWorkflows:
            return workflowService.listWorkflows()

        case .createWorkflow(let name, let commands):
            return workflowService.createWorkflow(name: name, commands: commands)

        case .deleteWorkflow(let name):
            return workflowService.deleteWorkflow(name: name)

        case .runWorkflow:
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "runWorkflow se coordina fuera del executor",
                userMessage: "Voy a ejecutar ese workflow."
            )

        case .shutdownMac:
            return appService.shutdownMac()

        case .unknown:
            return AssistantExecutionResult(
                success: false,
                technicalMessage: "Acción desconocida",
                userMessage: "No entendí esa acción."
            )
        }
    }
}
