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
        memoryStore: MemoryStore,
        workflowStore: WorkflowStore,
        installedAppsIndex: InstalledAppsIndex,
        userFilesIndex: UserFilesIndex
    ) {
        self.appService = AppExecutionService(installedAppsIndex: installedAppsIndex)
        self.fileService = FileExecutionService(userFilesIndex: userFilesIndex)
        self.folderService = FolderExecutionService()
        self.webService = WebExecutionService()
        self.memoryService = MemoryExecutionService(memoryStore: memoryStore)
        self.workflowService = WorkflowExecutionService(workflowStore: workflowStore)
    }

    func execute(_ action: AssistantAction) -> AssistantExecutionResult {
        switch action {
        case .searchGoogle(let query):
            return webService.searchGoogle(query)

        case .openWebsite(let url):
            return webService.openWebsite(url)

        case .openApp(let name):
            return appService.openApp(named: name)

        case .searchInsideWebsite(let site, let query):
            return webService.searchInsideWebsite(site: site, query: query)

        case .openFolder(let path):
            return folderService.openFolder(path)

        case .createFolder(let basePath, let folderName):
            return folderService.createFolder(basePath: basePath, folderName: folderName)

        case .openFile(let path):
            return fileService.openFile(at: path)

        case .findFile(let query):
            return fileService.findFile(query: query)

        case .quitApp(let name):
            return appService.quitApp(named: name)

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
            return memoryService.formattedFullMemory()

        case .listFolderAliases:
            return memoryService.formattedFolderAliases()

        case .listAppAliases:
            return memoryService.formattedAppAliases()

        case .listWebsiteAliases:
            return memoryService.formattedWebsiteAliases()

        case .clearMemory:
            return memoryService.clearMemory()

        case .listWorkflows:
            return workflowService.formattedWorkflows()

        case .createWorkflow(let name, let commands):
            return workflowService.createWorkflow(name: name, commands: commands)

        case .deleteWorkflow(let name):
            return workflowService.deleteWorkflow(named: name)

        case .runWorkflow:
            return AssistantExecutionResult(
                success: true,
                technicalMessage: "runWorkflow se gestiona desde AssistantViewModel",
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
