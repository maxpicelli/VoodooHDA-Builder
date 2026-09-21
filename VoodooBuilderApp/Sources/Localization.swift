import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case ptBR
    case eng

    var id: String { rawValue }

    var pickerTitle: String {
        switch self {
        case .ptBR:
            return "PT-BR"
        case .eng:
            return "ENG"
        }
    }
}

enum ArtifactDescription {
    case prefPane
    case copiedPrefPane
    case kext
    case copiedKext
    case installerKext
    case installerPrefPane
    case installerScript
    case installerTemplate
    case compiledKext
    case compiledPrefPane
    case prefPaneIcon
    case package
    case customKext
    case customPrefPane

    func text(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.prefPane, _):
            return "pref pane"
        case (.copiedPrefPane, .ptBR):
            return "pref pane copiada"
        case (.copiedPrefPane, .eng):
            return "copied pref pane"
        case (.kext, _):
            return "kext"
        case (.copiedKext, .ptBR):
            return "kext copiada"
        case (.copiedKext, .eng):
            return "copied kext"
        case (.installerKext, .ptBR):
            return "kext na pasta do instalador"
        case (.installerKext, .eng):
            return "kext in installer folder"
        case (.installerPrefPane, .ptBR):
            return "pref pane na pasta do instalador"
        case (.installerPrefPane, .eng):
            return "pref pane in installer folder"
        case (.installerScript, _):
            return "makeInstall.sh"
        case (.installerTemplate, .ptBR):
            return "template do instalador"
        case (.installerTemplate, .eng):
            return "installer template"
        case (.compiledKext, .ptBR):
            return "kext Release compilada"
        case (.compiledKext, .eng):
            return "compiled Release kext"
        case (.compiledPrefPane, .ptBR):
            return "pref pane Release compilada"
        case (.compiledPrefPane, .eng):
            return "compiled Release pref pane"
        case (.prefPaneIcon, .ptBR):
            return "icone do pref pane"
        case (.prefPaneIcon, .eng):
            return "pref pane icon"
        case (.package, _):
            return "pkg"
        case (.customKext, .ptBR):
            return "kext selecionada"
        case (.customKext, .eng):
            return "selected kext"
        case (.customPrefPane, .ptBR):
            return "pref pane selecionada"
        case (.customPrefPane, .eng):
            return "selected pref pane"
        }
    }
}

enum BuildStatus {
    case ready
    case stepSucceeded(PipelineStep)
    case allSucceeded
    case failed(PipelineStep?)

    func text(totalStepCount: Int, language: AppLanguage) -> String {
        switch self {
        case .ready:
            return AppStrings.ready(language)
        case .stepSucceeded(let step):
            return AppStrings.successMessage(for: step, totalStepCount: totalStepCount, language: language)
        case .allSucceeded:
            return AppStrings.allSucceeded(totalStepCount: totalStepCount, language: language)
        case .failed(let step):
            return AppStrings.failure(step: step, language: language)
        }
    }
}

enum AppStrings {
    static func subtitle(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Compila kext, pref pane e gera o instalador sem alterar o fluxo original."
        case .eng:
            return "Builds the kext, pref pane, and installer without changing the original flow."
        }
    }

    static func languageLabel(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Idioma"
        case .eng:
            return "Language"
        }
    }

    static func statusLabel(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR, .eng:
            return "Status"
        }
    }

    static func ready(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Pronto"
        case .eng:
            return "Ready"
        }
    }

    static func readyBadge(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "PRONTO"
        case .eng:
            return "READY"
        }
    }

    static func runningBadge(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "EM EXECUCAO"
        case .eng:
            return "RUNNING"
        }
    }

    static func processingButton(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Processando..."
        case .eng:
            return "Processing..."
        }
    }

    static func buildButton(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Criar VoodooHDA.pkg"
        case .eng:
            return "Create VoodooHDA.pkg"
        }
    }

    static func autoOpenNote(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "O instalador abre automaticamente quando o pacote terminar de ser gerado."
        case .eng:
            return "The installer opens automatically when the package finishes building."
        }
    }

    static func runningProgress(completed: Int, total: Int, step: PipelineStep, language: AppLanguage) -> String {
        "\(completed)/\(total)  \(step.title(for: language))"
    }

    static func successMessage(for step: PipelineStep, totalStepCount: Int, language: AppLanguage) -> String {
        switch (step, language) {
        case (.removePrevious, .ptBR):
            return "Remocao concluida"
        case (.removePrevious, .eng):
            return "Removal complete"
        case (.buildKext, .ptBR):
            return "1/\(totalStepCount)  Kext pronta"
        case (.buildKext, .eng):
            return "1/\(totalStepCount)  Kext ready"
        case (.buildPrefPane, .ptBR):
            return "2/\(totalStepCount)  Pref pane pronta"
        case (.buildPrefPane, .eng):
            return "2/\(totalStepCount)  Pref pane ready"
        case (.buildInstaller, .ptBR):
            return "3/\(totalStepCount)  VoodooHDA.pkg pronto"
        case (.buildInstaller, .eng):
            return "3/\(totalStepCount)  VoodooHDA.pkg ready"
        case (.packageCustomKext, .ptBR):
            return "Pacote da kext propria pronto"
        case (.packageCustomKext, .eng):
            return "Custom kext package ready"
        }
    }

    static func allSucceeded(totalStepCount: Int, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "\(totalStepCount)/\(totalStepCount)  VoodooHDA.pkg pronto"
        case .eng:
            return "\(totalStepCount)/\(totalStepCount)  VoodooHDA.pkg ready"
        }
    }

    static func failure(step: PipelineStep?, language: AppLanguage) -> String {
        if let step {
            switch language {
            case .ptBR:
                return "Falhou: \(step.title(for: language))"
            case .eng:
                return "Failed: \(step.title(for: language))"
            }
        }

        switch language {
        case .ptBR:
            return "Falhou"
        case .eng:
            return "Failed"
        }
    }

    static func downloadingRepository(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Baixando VoodooHDA do GitHub para \(path).\n"
        case .eng:
            return "Downloading VoodooHDA from GitHub into \(path).\n"
        }
    }

    static func localRepositoryWithoutGit(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Repositorio local encontrado em \(path). Pulando atualizacao git porque a pasta nao tem .git.\n"
        case .eng:
            return "Local repository found at \(path). Skipping git update because the folder has no .git.\n"
        }
    }

    static func updatingRepository(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Repositorio local encontrado. Atualizando checkout do VoodooHDA.\n"
        case .eng:
            return "Local repository found. Updating VoodooHDA checkout.\n"
        }
    }

    static func foundKernelSDK(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "MacKernelSDK local encontrado em \(path).\n"
        case .eng:
            return "Local MacKernelSDK found at \(path).\n"
        }
    }

    static func kernelSDKLinkExists(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Link MacKernelSDK ja existe em \(path).\n"
        case .eng:
            return "MacKernelSDK link already exists at \(path).\n"
        }
    }

    static func generatingGitCommitHeader(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Gerando \(path) a partir do commit atual do VoodooHDA.\n"
        case .eng:
            return "Generating \(path) from the current VoodooHDA commit.\n"
        }
    }

    static func prefPaneBuilt(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Pref pane gerada em \(path).\n"
        case .eng:
            return "Pref pane built at \(path).\n"
        }
    }

    static func prefPaneCopied(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Pref pane copiada para \(path).\n"
        case .eng:
            return "Pref pane copied to \(path).\n"
        }
    }

    static func kextBuilt(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Kext gerada em \(path).\n"
        case .eng:
            return "Kext built at \(path).\n"
        }
    }

    static func kextCopied(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Kext copiada para \(path).\n"
        case .eng:
            return "Kext copied to \(path).\n"
        }
    }

    static func packageIconApplied(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Icone aplicado ao pkg gerado.\n"
        case .eng:
            return "Applied icon to generated pkg.\n"
        }
    }

    static func packageOpened(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "VoodooHDA.pkg aberto a partir de \(path).\n"
        case .eng:
            return "Opened VoodooHDA.pkg from \(path).\n"
        }
    }

    static func installerFolderOpened(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Pasta VoodooHDA-Installer-Work aberta no Finder.\n"
        case .eng:
            return "Opened VoodooHDA-Installer-Work in Finder.\n"
        }
    }

    static func removeVoodooButton(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Remover VoodooHDA"
        case .eng:
            return "Remove VoodooHDA"
        }
    }

    static func removeConfirmTitle(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Remover VoodooHDA do sistema?"
        case .eng:
            return "Remove VoodooHDA from the system?"
        }
    }

    static func removeConfirmMessage(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Isso fecha as Preferencias/Ajustes do Sistema e apaga a kext, o pref pane e os arquivos relacionados do VoodooHDA. Vai pedir sua senha de administrador. Essa acao nao pode ser desfeita."
        case .eng:
            return "This closes System Preferences/Settings and deletes the VoodooHDA kext, pref pane, and related files. You'll be asked for your administrator password. This action cannot be undone."
        }
    }

    static func removeConfirmButton(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Remover"
        case .eng:
            return "Remove"
        }
    }

    static func cancelButton(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Cancelar"
        case .eng:
            return "Cancel"
        }
    }

    static func pathNotFound(description: String, path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Nao encontrei \(description) em \(path)"
        case .eng:
            return "Could not find \(description) at \(path)"
        }
    }

    static func couldNotLoadIcon(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Nao consegui carregar o icone em \(path)"
        case .eng:
            return "Could not load icon at \(path)"
        }
    }

    static func couldNotApplyIcon(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Nao consegui aplicar o icone ao pkg em \(path)"
        case .eng:
            return "Could not apply icon to pkg at \(path)"
        }
    }

    static func buildTabTitle(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Compilar"
        case .eng:
            return "Build"
        }
    }

    static func customTabTitle(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Kext propria"
        case .eng:
            return "Own kext"
        }
    }

    static func installedLabel(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Instalado"
        case .eng:
            return "Installed"
        }
    }

    static func notInstalled(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "VoodooHDA nao instalado neste Mac"
        case .eng:
            return "VoodooHDA not installed on this Mac"
        }
    }

    static func installedSummary(kext: String?, prefPane: String?, language: AppLanguage) -> String {
        let prefPaneLabel = language == .ptBR ? "painel" : "panel"
        var parts: [String] = []

        if let kext { parts.append("kext \(kext)") }
        if let prefPane { parts.append("\(prefPaneLabel) \(prefPane)") }

        guard !parts.isEmpty else { return notInstalled(language) }
        return installedLabel(language) + ": " + parts.joined(separator: "  ·  ")
    }

    static func refreshInstalledTooltip(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Verificar versao instalada novamente"
        case .eng:
            return "Check the installed version again"
        }
    }

    static func customKextFieldLabel(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "VoodooHDA.kext"
        case .eng:
            return "VoodooHDA.kext"
        }
    }

    static func customPrefPaneFieldLabel(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Pref pane (opcional)"
        case .eng:
            return "Pref pane (optional)"
        }
    }

    static func chooseButton(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Escolher..."
        case .eng:
            return "Choose..."
        }
    }

    static func nothingSelected(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Nenhum selecionado"
        case .eng:
            return "None selected"
        }
    }

    static func dropHint(fileExtension: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "arraste a .\(fileExtension) aqui"
        case .eng:
            return "drop the .\(fileExtension) here"
        }
    }

    static func templatePrefPaneFallback(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Usando a pref pane do template"
        case .eng:
            return "Using the template pref pane"
        }
    }

    static func customPackageButton(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Gerar pacote"
        case .eng:
            return "Create package"
        }
    }

    static func customOutputNote(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Saida: \(path)"
        case .eng:
            return "Output: \(path)"
        }
    }

    static func customKextNotSelected(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Selecione uma VoodooHDA.kext antes de gerar o pacote."
        case .eng:
            return "Select a VoodooHDA.kext before creating the package."
        }
    }

    static func customPackageFolder(path: String, version: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Empacotando kext versao \(version) em \(path).\n"
        case .eng:
            return "Packaging kext version \(version) into \(path).\n"
        }
    }

    static func customPackageBuilt(path: String, language: AppLanguage) -> String {
        switch language {
        case .ptBR:
            return "Pacote gerado em \(path).\n"
        case .eng:
            return "Package created at \(path).\n"
        }
    }
}

extension PipelineStep {
    func title(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.removePrevious, .ptBR):
            return "Removendo versoes anteriores"
        case (.removePrevious, .eng):
            return "Removing previous versions"
        case (.buildKext, .ptBR):
            return "Compilando kext"
        case (.buildKext, .eng):
            return "Building kext"
        case (.buildPrefPane, .ptBR):
            return "Compilando pref pane"
        case (.buildPrefPane, .eng):
            return "Building pref pane"
        case (.buildInstaller, .ptBR):
            return "Gerando VoodooHDA.pkg"
        case (.buildInstaller, .eng):
            return "Generating VoodooHDA.pkg"
        case (.packageCustomKext, .ptBR):
            return "Empacotando kext propria"
        case (.packageCustomKext, .eng):
            return "Packaging custom kext"
        }
    }
}