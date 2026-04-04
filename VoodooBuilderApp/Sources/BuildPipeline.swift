import AppKit
import Foundation

enum PipelineStep: String, CaseIterable, Identifiable {
    case removePrevious = "Removendo versoes anteriores"
    case buildKext = "Compilando kext"
    case buildPrefPane = "Compilando pref pane"
    case buildInstaller = "Gerando VoodooHDA.pkg"

    var id: String { rawValue }
}

@MainActor
final class BuildPipeline {
    private let runner = ShellCommandRunner()
    private let fileManager = FileManager.default
    private let dynamicInstallerItems: Set<String> = [
        "VoodooHDA.kext",
        "VoodooHDA.prefPane",
        "Kext.pkg",
        "prefpane.pkg",
        "getdump.pkg",
        "VoodooHDA.pkg"
    ]

    func run(step: PipelineStep, configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        switch step {
        case .removePrevious:
            try await removePrevious(configuration: configuration, appendLog: appendLog)
        case .buildPrefPane:
            try await buildPrefPane(configuration: configuration, appendLog: appendLog)
        case .buildKext:
            try await buildKext(configuration: configuration, appendLog: appendLog)
        case .buildInstaller:
            try await buildInstaller(configuration: configuration, appendLog: appendLog)
        }
    }

    private func prepareRepository(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        try fileManager.createDirectory(atPath: configuration.workspaceDirectory, withIntermediateDirectories: true)

        if !fileManager.fileExists(atPath: configuration.repositoryDirectory) {
            appendLog("Baixando VoodooHDA do GitHub para \(configuration.repositoryDirectory).\n")
            let command = "git clone \(configuration.repositoryURL.shellQuoted) \(configuration.repositoryDirectory.shellQuoted)"
            _ = try await runner.run(command, in: configuration.workspaceDirectory, onOutput: appendLog)
            return
        }

        let gitDirectory = configuration.repositoryDirectory + "/.git"
        guard fileManager.fileExists(atPath: gitDirectory) else {
            appendLog("Repositorio local encontrado em \(configuration.repositoryDirectory). Pulando atualizacao git porque a pasta nao tem .git.\n")
            return
        }

        appendLog("Repositorio local encontrado. Atualizando checkout do VoodooHDA.\n")
        _ = try await runner.run("git fetch --all --tags --prune", in: configuration.repositoryDirectory, onOutput: appendLog)
        _ = try await runner.run("git pull --ff-only", in: configuration.repositoryDirectory, onOutput: appendLog)
    }

    private func prepareKernelSDK(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        try fileManager.createDirectory(atPath: configuration.workspaceDirectory, withIntermediateDirectories: true)

        if !fileManager.fileExists(atPath: configuration.kernelSDKDirectory) {
            let cloneCommand = "git clone https://github.com/joevt/MacKernelSDK.git \(configuration.kernelSDKDirectory.shellQuoted)"
            _ = try await runner.run(cloneCommand, in: configuration.workspaceDirectory, onOutput: appendLog)
        } else {
            appendLog("MacKernelSDK local encontrado em \(configuration.kernelSDKDirectory).\n")
        }

        let symlinkPath = configuration.repositoryDirectory + "/MacKernelSDK"

        if fileManager.fileExists(atPath: symlinkPath) || (try? fileManager.destinationOfSymbolicLink(atPath: symlinkPath)) != nil {
            appendLog("Link MacKernelSDK ja existe em \(symlinkPath).\n")
            return
        }

        let linkCommand = "ln -s \(configuration.kernelSDKDirectory.shellQuoted) \(symlinkPath.shellQuoted)"
        _ = try await runner.run(linkCommand, in: configuration.workspaceDirectory, onOutput: appendLog)
    }

    private func removePrevious(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        let command = "rm -rf /Library/Extensions/VoodooHDA.kext /Library/LaunchAgents/org.voodoo.driver.plist '/Library/Application Support/VoodooHDA' /System/Library/Extensions/VoodooHDA.kext /Library/Extensions/VoodooHDA.kext /Library/PreferencePanes/VoodooHDA.prefPane && find /Users -type d -path '*/Library/PreferencePanes/VoodooHDA.prefPane' -prune -exec rm -rf {} + 2>/dev/null || true && if command -v kextcache >/dev/null 2>&1; then kextcache -i / || true; fi"
        _ = try await runner.run(command, in: configuration.workspaceDirectory, onOutput: appendLog)
    }

    private func buildPrefPane(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        try await prepareRepository(configuration: configuration, appendLog: appendLog)
        try await prepareKernelSDK(configuration: configuration, appendLog: appendLog)
        try prepareInstallerWorkspace(configuration: configuration, reset: false)

        let command = "xcodebuild -project ./VHDAPrefPane/VoodooHDA/VoodooHDA.xcodeproj -alltargets -configuration Release build"
        _ = try await runner.run(command, in: configuration.repositoryDirectory, onOutput: appendLog)
        try ensurePathExists(configuration.prefPaneOutputPath, description: "pref pane")
        appendLog("Pref pane gerada em \(configuration.prefPaneOutputPath).\n")

        let prefPaneDestination = configuration.installerWorkingDirectory + "/VoodooHDA.prefPane"
        try replaceItem(at: prefPaneDestination, with: configuration.prefPaneOutputPath)
        try ensurePathExists(prefPaneDestination, description: "pref pane copiada")
        appendLog("Pref pane copiada para \(prefPaneDestination).\n")
    }

    private func buildKext(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        try await prepareRepository(configuration: configuration, appendLog: appendLog)
        try await prepareKernelSDK(configuration: configuration, appendLog: appendLog)
        try prepareInstallerWorkspace(configuration: configuration, reset: false)

        let command = "xcodebuild -project ./tranc/VoodooHDA_BS.xcodeproj -target VoodooHDA -configuration Release build"
        _ = try await runner.run(command, in: configuration.repositoryDirectory, onOutput: appendLog)
        try ensurePathExists(configuration.kextOutputPath, description: "kext")
        appendLog("Kext gerada em \(configuration.kextOutputPath).\n")

        let kextDestination = configuration.installerWorkingDirectory + "/VoodooHDA.kext"
        try replaceItem(at: kextDestination, with: configuration.kextOutputPath)
        try ensurePathExists(kextDestination, description: "kext copiada")
        appendLog("Kext copiada para \(kextDestination).\n")
    }

    private func buildInstaller(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        try prepareInstallerWorkspace(configuration: configuration, reset: false)
        try syncCompiledInstallerArtifacts(configuration: configuration)
        try ensurePathExists(configuration.installerWorkingDirectory + "/VoodooHDA.kext", description: "kext na pasta do instalador")
        try ensurePathExists(configuration.installerWorkingDirectory + "/VoodooHDA.prefPane", description: "pref pane na pasta do instalador")
        try ensurePathExists(configuration.installerScriptPath, description: "makeInstall.sh")
        let scriptDirectory = URL(fileURLWithPath: configuration.installerScriptPath).deletingLastPathComponent().path
        let command = "chmod +x \(configuration.installerScriptPath.shellQuoted) && ./makeInstall.sh"
        _ = try await runner.run(command, in: scriptDirectory, onOutput: appendLog)
        try ensurePathExists(configuration.outputPackagePath, description: "VoodooHDA.pkg")

        try applyPackageIcon(configuration: configuration, packagePath: configuration.outputPackagePath)
        appendLog("Icone aplicado ao pkg gerado.\n")

        let openPackageCommand = "open \(configuration.outputPackagePath.shellQuoted)"
        _ = try await runner.run(openPackageCommand, in: configuration.workspaceDirectory, onOutput: appendLog)
        appendLog("VoodooHDA.pkg aberto a partir de \(configuration.installerWorkingDirectory).\n")

        let openFolderCommand = "open \(configuration.installerWorkingDirectory.shellQuoted)"
        _ = try await runner.run(openFolderCommand, in: configuration.workspaceDirectory, onOutput: appendLog)
        appendLog("Pasta VoodooHDA-Installer-Work aberta no Finder.\n")
    }

    private func prepareInstallerWorkspace(configuration: BuildConfiguration, reset: Bool) throws {
        try ensurePathExists(configuration.installerTemplateDirectory, description: "template do instalador")

        if reset && fileManager.fileExists(atPath: configuration.installerWorkingDirectory) {
            try fileManager.removeItem(atPath: configuration.installerWorkingDirectory)
        }

        if fileManager.fileExists(atPath: configuration.installerWorkingDirectory) {
            try synchronizeInstallerTemplate(configuration: configuration)
            return
        }

        let parentDirectory = URL(fileURLWithPath: configuration.installerWorkingDirectory).deletingLastPathComponent()
        try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        try fileManager.copyItem(atPath: configuration.installerTemplateDirectory, toPath: configuration.installerWorkingDirectory)
    }

    private func synchronizeInstallerTemplate(configuration: BuildConfiguration) throws {
        let templateURL = URL(fileURLWithPath: configuration.installerTemplateDirectory, isDirectory: true)
        let workingURL = URL(fileURLWithPath: configuration.installerWorkingDirectory, isDirectory: true)
        let templateItems = try fileManager.contentsOfDirectory(at: templateURL, includingPropertiesForKeys: nil)

        for itemURL in templateItems {
            if dynamicInstallerItems.contains(itemURL.lastPathComponent) {
                continue
            }

            let destinationURL = workingURL.appendingPathComponent(itemURL.lastPathComponent, isDirectory: true)

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.copyItem(at: itemURL, to: destinationURL)
        }
    }

    private func syncCompiledInstallerArtifacts(configuration: BuildConfiguration) throws {
        try ensurePathExists(configuration.kextOutputPath, description: "kext Release compilada")
        try ensurePathExists(configuration.prefPaneOutputPath, description: "pref pane Release compilada")

        let kextDestination = configuration.installerWorkingDirectory + "/VoodooHDA.kext"
        let prefPaneDestination = configuration.installerWorkingDirectory + "/VoodooHDA.prefPane"

        try replaceItem(at: kextDestination, with: configuration.kextOutputPath)
        try replaceItem(at: prefPaneDestination, with: configuration.prefPaneOutputPath)
    }

    private func ensurePathExists(_ path: String, description: String) throws {
        if !fileManager.fileExists(atPath: path) {
            throw NSError(domain: "VoodooBuilderApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Nao encontrei \(description) em \(path)"])
        }
    }

    private func replaceItem(at destination: String, with source: String) throws {
        if fileManager.fileExists(atPath: destination) {
            try fileManager.removeItem(atPath: destination)
        }
        try fileManager.copyItem(atPath: source, toPath: destination)
    }

    private func applyPackageIcon(configuration: BuildConfiguration, packagePath: String) throws {
        let iconPath: String

        if fileManager.fileExists(atPath: configuration.prefPaneIconPath) {
            iconPath = configuration.prefPaneIconPath
        } else {
            iconPath = configuration.sourcePrefPaneIconPath
        }

        try ensurePathExists(iconPath, description: "icone do pref pane")
        try ensurePathExists(packagePath, description: "pkg")

        guard let image = NSImage(contentsOfFile: iconPath) else {
            throw NSError(domain: "VoodooBuilderApp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Nao consegui carregar o icone em \(iconPath)"])
        }

        let success = NSWorkspace.shared.setIcon(image, forFile: packagePath, options: [])
        if !success {
            throw NSError(domain: "VoodooBuilderApp", code: 3, userInfo: [NSLocalizedDescriptionKey: "Nao consegui aplicar o icone ao pkg em \(packagePath)"])
        }
    }

}

private extension String {
    var shellQuoted: String {
        let escaped = replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }
}