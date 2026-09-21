import AppKit
import Foundation

enum PipelineStep: String, CaseIterable, Identifiable {
    case removePrevious
    case buildKext
    case buildPrefPane
    case buildInstaller
    case packageCustomKext

    var id: String { rawValue }
}

@MainActor
final class BuildPipeline {
    // O upstream ainda declara MACOSX_DEPLOYMENT_TARGET 10.13 (kext) e 11.5
    // (prefPane), valores recusados pelo Xcode 26+ (minimo 12.0). Como os alvos
    // sao sempre x86_64, forcamos a arquitetura para nao depender da arch ativa
    // ao compilar em Apple Silicon. Passamos tudo na linha de comando para nao
    // editar o clone do repositorio, que e sobrescrito a cada git pull.
    private static let xcodeBuildOverrides = "MACOSX_DEPLOYMENT_TARGET=12.0 ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO"

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
        case .packageCustomKext:
            try await packageCustomKext(configuration: configuration, appendLog: appendLog)
        }
    }

    private func prepareRepository(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        try fileManager.createDirectory(atPath: configuration.workspaceDirectory, withIntermediateDirectories: true)

        if !fileManager.fileExists(atPath: configuration.repositoryDirectory) {
            appendLog(AppStrings.downloadingRepository(path: configuration.repositoryDirectory, language: configuration.appLanguage))
            let command = "git clone \(configuration.repositoryURL.shellQuoted) \(configuration.repositoryDirectory.shellQuoted)"
            _ = try await runner.run(command, in: configuration.workspaceDirectory, onOutput: appendLog)
            return
        }

        let gitDirectory = configuration.repositoryDirectory + "/.git"
        guard fileManager.fileExists(atPath: gitDirectory) else {
            appendLog(AppStrings.localRepositoryWithoutGit(path: configuration.repositoryDirectory, language: configuration.appLanguage))
            return
        }

        appendLog(AppStrings.updatingRepository(configuration.appLanguage))
        _ = try await runner.run("git fetch --all --tags --prune", in: configuration.repositoryDirectory, onOutput: appendLog)
        _ = try await runner.run("git pull --ff-only", in: configuration.repositoryDirectory, onOutput: appendLog)
    }

    private func prepareKernelSDK(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        try fileManager.createDirectory(atPath: configuration.workspaceDirectory, withIntermediateDirectories: true)

        if !fileManager.fileExists(atPath: configuration.kernelSDKDirectory) {
            let cloneCommand = "git clone https://github.com/joevt/MacKernelSDK.git \(configuration.kernelSDKDirectory.shellQuoted)"
            _ = try await runner.run(cloneCommand, in: configuration.workspaceDirectory, onOutput: appendLog)
        } else {
            appendLog(AppStrings.foundKernelSDK(path: configuration.kernelSDKDirectory, language: configuration.appLanguage))
        }

        let symlinkPath = configuration.repositoryDirectory + "/MacKernelSDK"

        if fileManager.fileExists(atPath: symlinkPath) || (try? fileManager.destinationOfSymbolicLink(atPath: symlinkPath)) != nil {
            appendLog(AppStrings.kernelSDKLinkExists(path: symlinkPath, language: configuration.appLanguage))
            return
        }

        let linkCommand = "ln -s \(configuration.kernelSDKDirectory.shellQuoted) \(symlinkPath.shellQuoted)"
        _ = try await runner.run(linkCommand, in: configuration.workspaceDirectory, onOutput: appendLog)
    }

    // Remocao requer privilegios de root para apagar itens em /Library e
    // /System/Library. Em vez de chamar sudo diretamente (que trava esperando
    // senha em um processo sem terminal), delegamos a elevacao ao
    // Authorization Services do macOS via osascript, que exibe o dialogo
    // nativo de autenticacao do sistema.
    private func removePrevious(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        let command = #"osascript -e 'do shell script "killall \"System Preferences\" >/dev/null 2>&1; killall \"System Settings\" >/dev/null 2>&1; rm -rf /Library/Extensions/VoodooHDA.kext /Library/LaunchAgents/org.voodoo.driver.plist \"/Library/Application Support/VoodooHDA\" /System/Library/Extensions/VoodooHDA.kext /Library/PreferencePanes/VoodooHDA.prefPane; find /Users -type d -path \"*/Library/PreferencePanes/VoodooHDA.prefPane\" -prune -exec rm -rf {} + >/dev/null 2>&1; if command -v kextcache >/dev/null 2>&1; then kextcache -i / >/dev/null 2>&1; fi; true" with administrator privileges'"#
        _ = try await runner.run(command, in: configuration.workspaceDirectory, onOutput: appendLog)
    }

    // O upstream VoodooHDA/tranc/VoodooHDADevice.cpp inclui "GitCommit.h", mas esse
    // arquivo nao e versionado no repositorio (e gerado localmente). Sem ele o
    // clang falha com "'GitCommit.h' file not found". Geramos o header aqui, a
    // cada build do kext, para que futuras atualizacoes do repositorio original
    // continuem compilando sem intervencao manual.
    private func ensureGitCommitHeader(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        let headerPath = configuration.repositoryDirectory + "/tranc/GitCommit.h"
        appendLog(AppStrings.generatingGitCommitHeader(path: headerPath, language: configuration.appLanguage))
        let command = "mkdir -p tranc && commit=$(git rev-parse --short HEAD 2>/dev/null || echo unknown) && printf '#pragma once\\n#define VOODOO_HDA_GIT_COMMIT \"%s\"\\n' \"$commit\" > tranc/GitCommit.h"
        _ = try await runner.run(command, in: configuration.repositoryDirectory, onOutput: appendLog)
    }

    private func buildPrefPane(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        try await prepareRepository(configuration: configuration, appendLog: appendLog)
        try await prepareKernelSDK(configuration: configuration, appendLog: appendLog)
        try prepareInstallerWorkspace(configuration: configuration, reset: false)

        let command = "xcodebuild -project ./VHDAPrefPane/VoodooHDA/VoodooHDA.xcodeproj -alltargets -configuration Release \(Self.xcodeBuildOverrides) build"
        _ = try await runner.run(command, in: configuration.repositoryDirectory, onOutput: appendLog)
        try ensurePathExists(configuration.prefPaneOutputPath, description: ArtifactDescription.prefPane.text(for: configuration.appLanguage), language: configuration.appLanguage)
        appendLog(AppStrings.prefPaneBuilt(path: configuration.prefPaneOutputPath, language: configuration.appLanguage))

        let prefPaneDestination = configuration.installerWorkingDirectory + "/VoodooHDA.prefPane"
        try replaceItem(at: prefPaneDestination, with: configuration.prefPaneOutputPath)
        try ensurePathExists(prefPaneDestination, description: ArtifactDescription.copiedPrefPane.text(for: configuration.appLanguage), language: configuration.appLanguage)
        appendLog(AppStrings.prefPaneCopied(path: prefPaneDestination, language: configuration.appLanguage))
    }

    private func buildKext(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        try await prepareRepository(configuration: configuration, appendLog: appendLog)
        try await prepareKernelSDK(configuration: configuration, appendLog: appendLog)
        try prepareInstallerWorkspace(configuration: configuration, reset: false)
        try await ensureGitCommitHeader(configuration: configuration, appendLog: appendLog)

        let command = "xcodebuild -project ./tranc/VoodooHDA_BS.xcodeproj -target VoodooHDA -configuration Release \(Self.xcodeBuildOverrides) build"
        _ = try await runner.run(command, in: configuration.repositoryDirectory, onOutput: appendLog)
        try ensurePathExists(configuration.kextOutputPath, description: ArtifactDescription.kext.text(for: configuration.appLanguage), language: configuration.appLanguage)
        appendLog(AppStrings.kextBuilt(path: configuration.kextOutputPath, language: configuration.appLanguage))

        let kextDestination = configuration.installerWorkingDirectory + "/VoodooHDA.kext"
        try replaceItem(at: kextDestination, with: configuration.kextOutputPath)
        try ensurePathExists(kextDestination, description: ArtifactDescription.copiedKext.text(for: configuration.appLanguage), language: configuration.appLanguage)
        appendLog(AppStrings.kextCopied(path: kextDestination, language: configuration.appLanguage))
    }

    private func buildInstaller(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        try prepareInstallerWorkspace(configuration: configuration, reset: false)
        try syncCompiledInstallerArtifacts(configuration: configuration)
        try ensurePathExists(configuration.installerWorkingDirectory + "/VoodooHDA.kext", description: ArtifactDescription.installerKext.text(for: configuration.appLanguage), language: configuration.appLanguage)
        try ensurePathExists(configuration.installerWorkingDirectory + "/VoodooHDA.prefPane", description: ArtifactDescription.installerPrefPane.text(for: configuration.appLanguage), language: configuration.appLanguage)
        try ensurePathExists(configuration.installerScriptPath, description: ArtifactDescription.installerScript.text(for: configuration.appLanguage), language: configuration.appLanguage)
        let scriptDirectory = URL(fileURLWithPath: configuration.installerScriptPath).deletingLastPathComponent().path
        let command = "chmod +x \(configuration.installerScriptPath.shellQuoted) && ./makeInstall.sh"
        _ = try await runner.run(command, in: scriptDirectory, onOutput: appendLog)
        try ensurePathExists(configuration.outputPackagePath, description: "VoodooHDA.pkg", language: configuration.appLanguage)

        try applyPackageIcon(configuration: configuration, packagePath: configuration.outputPackagePath)
        appendLog(AppStrings.packageIconApplied(configuration.appLanguage))

        let openPackageCommand = "open \(configuration.outputPackagePath.shellQuoted)"
        _ = try await runner.run(openPackageCommand, in: configuration.workspaceDirectory, onOutput: appendLog)
        appendLog(AppStrings.packageOpened(path: configuration.installerWorkingDirectory, language: configuration.appLanguage))

        let openFolderCommand = "open \(configuration.installerWorkingDirectory.shellQuoted)"
        _ = try await runner.run(openFolderCommand, in: configuration.workspaceDirectory, onOutput: appendLog)
        appendLog(AppStrings.installerFolderOpened(configuration.appLanguage))
    }

    // Empacota uma VoodooHDA.kext ja pronta, sem compilar nada. Reaproveita o
    // template/makeInstall.sh do fluxo principal, mas em uma pasta de saida
    // separada, nomeada com a versao lida do Info.plist da kext escolhida.
    private func packageCustomKext(configuration: BuildConfiguration, appendLog: @escaping (String) -> Void) async throws {
        let language = configuration.appLanguage
        let kextPath = configuration.customKextPath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !kextPath.isEmpty else {
            throw NSError(domain: "VoodooBuilderApp", code: 10, userInfo: [NSLocalizedDescriptionKey: AppStrings.customKextNotSelected(language)])
        }

        try ensurePathExists(kextPath, description: ArtifactDescription.customKext.text(for: language), language: language)
        try ensurePathExists(configuration.installerTemplateDirectory, description: ArtifactDescription.installerTemplate.text(for: language), language: language)

        let kextVersion = InstalledVoodooInfo.bundleVersion(atBundlePath: kextPath) ?? "custom"
        let workingDirectory = configuration.customPackageDirectory(version: kextVersion)
        appendLog(AppStrings.customPackageFolder(path: workingDirectory, version: kextVersion, language: language))

        if fileManager.fileExists(atPath: workingDirectory) {
            try fileManager.removeItem(atPath: workingDirectory)
        }

        let parentDirectory = URL(fileURLWithPath: workingDirectory).deletingLastPathComponent()
        try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        try fileManager.copyItem(atPath: configuration.installerTemplateDirectory, toPath: workingDirectory)

        try replaceItem(at: workingDirectory + "/VoodooHDA.kext", with: kextPath)

        let customPrefPane = configuration.customPrefPanePath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !customPrefPane.isEmpty {
            try ensurePathExists(customPrefPane, description: ArtifactDescription.customPrefPane.text(for: language), language: language)
            try replaceItem(at: workingDirectory + "/VoodooHDA.prefPane", with: customPrefPane)
        }

        let prefPanePath = workingDirectory + "/VoodooHDA.prefPane"
        try ensurePathExists(prefPanePath, description: ArtifactDescription.installerPrefPane.text(for: language), language: language)

        try updateDistributionVersion(workingDirectory: workingDirectory, identifier: "org.voodoo.driver.VoodooHDA", version: kextVersion)
        if let prefPaneVersion = InstalledVoodooInfo.bundleVersion(atBundlePath: prefPanePath) {
            try updateDistributionVersion(workingDirectory: workingDirectory, identifier: "org.voodoo.VoodooHDA", version: prefPaneVersion)
        }

        let scriptPath = workingDirectory + "/makeInstall.sh"
        try ensurePathExists(scriptPath, description: ArtifactDescription.installerScript.text(for: language), language: language)
        _ = try await runner.run("chmod +x ./makeInstall.sh && ./makeInstall.sh", in: workingDirectory, onOutput: appendLog)

        let packagePath = workingDirectory + "/VoodooHDA.pkg"
        try ensurePathExists(packagePath, description: "VoodooHDA.pkg", language: language)

        if applyBestEffortPackageIcon(configuration: configuration, packagePath: packagePath, prefPanePath: prefPanePath) {
            appendLog(AppStrings.packageIconApplied(language))
        }

        appendLog(AppStrings.customPackageBuilt(path: packagePath, language: language))
        _ = try await runner.run("open \(workingDirectory.shellQuoted)", in: workingDirectory, onOutput: appendLog)
    }

    private func updateDistributionVersion(workingDirectory: String, identifier: String, version: String) throws {
        let distributionPath = workingDirectory + "/dist.xml"
        guard fileManager.fileExists(atPath: distributionPath) else { return }

        let contents = try String(contentsOfFile: distributionPath, encoding: .utf8)
        let pattern = "(<pkg-ref\\s+id=\"\(NSRegularExpression.escapedPattern(for: identifier))\"\\s+version=\")[^\"]*(\")"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let range = NSRange(contents.startIndex..<contents.endIndex, in: contents)
        let escapedVersion = version.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
        let template = "$1\(NSRegularExpression.escapedTemplate(for: escapedVersion))$2"
        let updated = regex.stringByReplacingMatches(in: contents, range: range, withTemplate: template)

        guard updated != contents else { return }
        try updated.write(toFile: distributionPath, atomically: true, encoding: .utf8)
    }

    private func applyBestEffortPackageIcon(configuration: BuildConfiguration, packagePath: String, prefPanePath: String) -> Bool {
        let candidates = [
            prefPanePath + "/Contents/Resources/VoodooHDAPref.icns",
            configuration.prefPaneIconPath,
            configuration.sourcePrefPaneIconPath
        ]

        guard
            let iconPath = candidates.first(where: { fileManager.fileExists(atPath: $0) }),
            let image = NSImage(contentsOfFile: iconPath)
        else {
            return false
        }

        return NSWorkspace.shared.setIcon(image, forFile: packagePath, options: [])
    }

    private func prepareInstallerWorkspace(configuration: BuildConfiguration, reset: Bool) throws {
        try ensurePathExists(configuration.installerTemplateDirectory, description: ArtifactDescription.installerTemplate.text(for: configuration.appLanguage), language: configuration.appLanguage)

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
        try ensurePathExists(configuration.kextOutputPath, description: ArtifactDescription.compiledKext.text(for: configuration.appLanguage), language: configuration.appLanguage)
        try ensurePathExists(configuration.prefPaneOutputPath, description: ArtifactDescription.compiledPrefPane.text(for: configuration.appLanguage), language: configuration.appLanguage)

        let kextDestination = configuration.installerWorkingDirectory + "/VoodooHDA.kext"
        let prefPaneDestination = configuration.installerWorkingDirectory + "/VoodooHDA.prefPane"

        try replaceItem(at: kextDestination, with: configuration.kextOutputPath)
        try replaceItem(at: prefPaneDestination, with: configuration.prefPaneOutputPath)
    }

    private func ensurePathExists(_ path: String, description: String, language: AppLanguage) throws {        if !fileManager.fileExists(atPath: path) {
            throw NSError(domain: "VoodooBuilderApp", code: 1, userInfo: [NSLocalizedDescriptionKey: AppStrings.pathNotFound(description: description, path: path, language: language)])
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

        try ensurePathExists(iconPath, description: ArtifactDescription.prefPaneIcon.text(for: configuration.appLanguage), language: configuration.appLanguage)
        try ensurePathExists(packagePath, description: ArtifactDescription.package.text(for: configuration.appLanguage), language: configuration.appLanguage)

        guard let image = NSImage(contentsOfFile: iconPath) else {
            throw NSError(domain: "VoodooBuilderApp", code: 2, userInfo: [NSLocalizedDescriptionKey: AppStrings.couldNotLoadIcon(path: iconPath, language: configuration.appLanguage)])
        }

        let success = NSWorkspace.shared.setIcon(image, forFile: packagePath, options: [])
        if !success {
            throw NSError(domain: "VoodooBuilderApp", code: 3, userInfo: [NSLocalizedDescriptionKey: AppStrings.couldNotApplyIcon(path: packagePath, language: configuration.appLanguage)])
        }
    }

}

private extension String {
    var shellQuoted: String {
        let escaped = replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }
}