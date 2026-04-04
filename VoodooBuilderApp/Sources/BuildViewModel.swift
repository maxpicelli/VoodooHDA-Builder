import Foundation
import SwiftUI

@MainActor
final class BuildViewModel: ObservableObject {
    private let totalStepCount = 3

    @Published var configuration: BuildConfiguration
    @Published var logOutput: String = ""
    @Published var isRunning = false
    @Published var activeStep: PipelineStep?
    @Published var statusMessage = "Pronto"
    @Published private var completedStepCount = 0

    var progressLine: String {
        if let step = activeStep {
            return "\(completedStepCount)/\(totalStepCount)  \(step.rawValue)"
        }

        return statusMessage
    }

    var progressValue: Double {
        let total = Double(totalStepCount)

        if isRunning {
            return min(Double(completedStepCount) + 0.5, total) / total
        }

        return min(Double(completedStepCount), total) / total
    }

    private let pipeline = BuildPipeline()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        if
            let data = try? Data(contentsOf: BuildConfiguration.storageURL),
            let stored = try? decoder.decode(BuildConfiguration.self, from: data)
        {
            configuration = stored
        } else {
            configuration = BuildConfiguration()
        }

        repairInvalidPathsIfNeeded()
    }

    func run(step: PipelineStep) {
        Task {
            await execute(step: step)
        }
    }

    func runAll() {
        Task {
            await executeAll()
        }
    }

    func persistConfiguration() {
        guard let data = try? encoder.encode(configuration) else { return }
        try? data.write(to: BuildConfiguration.storageURL)
    }

    private func repairInvalidPathsIfNeeded() {
        let normalizedWorkspace = BuildConfiguration.normalizeWorkspaceDirectory(configuration.workspaceDirectory)
        let hasLegacyRepositoryPath = configuration.repositoryDirectory == "//VoodooHDA"
            || configuration.repositoryDirectory == "/VoodooHDA"
            || configuration.repositoryDirectory.hasPrefix(BuildConfiguration.sourceRootDirectory)
            || configuration.repositoryDirectory.contains("/Sources/VoodooHDA")
        let hasLegacyInstallerPath = configuration.installerWorkingDirectory.hasPrefix(BuildConfiguration.sourceRootDirectory)
            || configuration.installerWorkingDirectory.contains("/Workspace/")

        guard normalizedWorkspace != configuration.workspaceDirectory || hasLegacyRepositoryPath || hasLegacyInstallerPath else {
            return
        }

        configuration = BuildConfiguration(
            repositoryURL: configuration.repositoryURL,
            workspaceDirectory: normalizedWorkspace,
            autoOpenInstaller: configuration.autoOpenInstaller,
            autoOpenOutputFolder: configuration.autoOpenOutputFolder
        )
        persistConfiguration()
    }

    private func execute(step: PipelineStep) async {
        guard !isRunning else { return }
        isRunning = true
        completedStepCount = completedCount(for: step)
        activeStep = step
        statusMessage = step.rawValue
        persistConfiguration()

        do {
            try await pipeline.run(step: step, configuration: configuration, appendLog: appendLog)
            completedStepCount = completedCount(for: step) + (step == .removePrevious ? 0 : 1)
            statusMessage = successMessage(for: step)
        } catch {
            statusMessage = "Falhou: \(step.rawValue)"
        }

        activeStep = nil
        isRunning = false
    }

    private func executeAll() async {
        guard !isRunning else { return }
        isRunning = true
        completedStepCount = 0
        statusMessage = PipelineStep.buildKext.rawValue
        persistConfiguration()

        let steps: [PipelineStep] = [.buildKext, .buildPrefPane, .buildInstaller]

        do {
            for (index, step) in steps.enumerated() {
                completedStepCount = index
                activeStep = step
                statusMessage = step.rawValue
                try await pipeline.run(step: step, configuration: configuration, appendLog: appendLog)
            }

            completedStepCount = steps.count
            statusMessage = "\(totalStepCount)/\(totalStepCount)  VoodooHDA.pkg pronto"
        } catch {
            if let step = activeStep {
                statusMessage = "Falhou: \(step.rawValue)"
            } else {
                statusMessage = "Falhou"
            }
        }

        activeStep = nil
        isRunning = false
    }

    private func successMessage(for step: PipelineStep) -> String {
        switch step {
        case .removePrevious:
            return "Remocao concluida"
        case .buildKext:
            return "1/3  Kext pronta"
        case .buildPrefPane:
            return "2/3  Pref pane pronta"
        case .buildInstaller:
            return "3/3  VoodooHDA.pkg pronto"
        }
    }

    private func completedCount(for step: PipelineStep) -> Int {
        switch step {
        case .removePrevious:
            return 0
        case .buildKext:
            return 0
        case .buildPrefPane:
            return 1
        case .buildInstaller:
            return 2
        }
    }

    private func appendLog(_ message: String) {
        logOutput.append(message)
    }
}