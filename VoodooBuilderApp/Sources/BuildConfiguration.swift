import Foundation

struct BuildConfiguration: Codable, Equatable {
    var repositoryURL: String = "https://github.com/CloverHackyColor/VoodooHDA.git"
    var workspaceDirectory: String
    var repositoryDirectory: String
    var installerTemplateDirectory: String
    var installerWorkingDirectory: String
    var kernelSDKDirectory: String
    var autoOpenInstaller: Bool
    var autoOpenOutputFolder: Bool

    init(
        repositoryURL: String = "https://github.com/CloverHackyColor/VoodooHDA.git",
        workspaceDirectory: String = BuildConfiguration.defaultWorkspaceDirectory,
        repositoryDirectory: String? = nil,
        installerTemplateDirectory: String? = nil,
        installerWorkingDirectory: String? = nil,
        kernelSDKDirectory: String? = nil,
        autoOpenInstaller: Bool = false,
        autoOpenOutputFolder: Bool = true
    ) {
        let normalizedWorkspaceDirectory = BuildConfiguration.normalizeWorkspaceDirectory(workspaceDirectory)
        let resolvedInstallerTemplateDirectory = installerTemplateDirectory ?? BuildConfiguration.defaultInstallerTemplateDirectory

        self.repositoryURL = repositoryURL
        self.workspaceDirectory = normalizedWorkspaceDirectory
        self.repositoryDirectory = repositoryDirectory ?? normalizedWorkspaceDirectory + "/VoodooHDA"
        self.installerTemplateDirectory = resolvedInstallerTemplateDirectory
        self.installerWorkingDirectory = installerWorkingDirectory ?? normalizedWorkspaceDirectory + "/VoodooHDA-Installer-Work"
        self.kernelSDKDirectory = kernelSDKDirectory ?? normalizedWorkspaceDirectory + "/MacKernelSDK"
        self.autoOpenInstaller = autoOpenInstaller
        self.autoOpenOutputFolder = autoOpenOutputFolder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let workspace = try container.decodeIfPresent(String.self, forKey: .workspaceDirectory) ?? BuildConfiguration.defaultWorkspaceDirectory
        let repositoryURL = try container.decodeIfPresent(String.self, forKey: .repositoryURL) ?? "https://github.com/CloverHackyColor/VoodooHDA.git"
        let autoOpenInstaller = try container.decodeIfPresent(Bool.self, forKey: .autoOpenInstaller) ?? false
        let autoOpenOutputFolder = try container.decodeIfPresent(Bool.self, forKey: .autoOpenOutputFolder) ?? true

        self.init(
            repositoryURL: repositoryURL,
            workspaceDirectory: workspace,
            autoOpenInstaller: autoOpenInstaller,
            autoOpenOutputFolder: autoOpenOutputFolder
        )
    }

    var prefPaneProjectPath: String {
        repositoryDirectory + "/VHDAPrefPane/VoodooHDA/VoodooHDA.xcodeproj"
    }

    var kextProjectPath: String {
        repositoryDirectory + "/tranc/VoodooHDA_BS.xcodeproj"
    }

    var prefPaneOutputPath: String {
        repositoryDirectory + "/VHDAPrefPane/VoodooHDA/build/Release/VoodooHDA.prefPane"
    }

    var prefPaneIconPath: String {
        prefPaneOutputPath + "/Contents/Resources/VoodooHDAPref.icns"
    }

    var sourcePrefPaneIconPath: String {
        repositoryDirectory + "/VHDAPrefPane/VoodooHDA/VoodooHDAPref.icns"
    }

    var kextOutputPath: String {
        repositoryDirectory + "/tranc/build/Release/VoodooHDA.kext"
    }

    var installerScriptPath: String {
        installerWorkingDirectory + "/makeInstall.sh"
    }

    var outputPackagePath: String {
        installerWorkingDirectory + "/VoodooHDA.pkg"
    }
}

extension BuildConfiguration {
    static var bundledInstallerTemplateDirectory: String? {
        Bundle.main.resourceURL?
            .appendingPathComponent("InstallerTemplate", isDirectory: true)
            .path
    }

    static var sourceRootDirectory: String {
        let bundleRoot = Bundle.main.object(forInfoDictionaryKey: "VoodooBuilderSourceRoot") as? String
        let normalized = normalizeWorkspaceDirectory(bundleRoot ?? "")

        if normalized.hasSuffix("/VoodooBuilderApp") {
            return normalized
        }

        let fallback = NSHomeDirectory() + "/Voodoo-HDA-builder-compiler/VoodooBuilderApp"
        return fallback
    }

    static var defaultWorkspaceDirectory: String {
        NSHomeDirectory()
    }

    static var defaultInstallerTemplateDirectory: String {
        if let bundledInstallerTemplateDirectory {
            return bundledInstallerTemplateDirectory
        }

        let sourceTemplate = sourceRootDirectory + "/Resources/InstallerTemplate"
        if FileManager.default.fileExists(atPath: sourceTemplate) {
            return sourceTemplate
        }

        let projectRoot = URL(fileURLWithPath: sourceRootDirectory).deletingLastPathComponent().path
        return projectRoot + "/VodooHDA-Installer-VoodooHDA-3.1.3-Tahoe-Raptor-LAKE"
    }

    static func normalizeWorkspaceDirectory(_ candidate: String) -> String {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = defaultWorkspaceDirectory

        guard !trimmed.isEmpty, trimmed != "/" else {
            return fallback
        }

        return URL(fileURLWithPath: trimmed).standardizedFileURL.path
    }

    static let storageURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("VoodooBuilderApp", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("config.json")
    }()
}