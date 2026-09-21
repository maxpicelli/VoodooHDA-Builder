import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private enum Tab: Hashable {
        case build
        case custom
    }

    @EnvironmentObject private var model: BuildViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showRemoveConfirmation = false
    @State private var selectedTab: Tab = .build

    private var language: AppLanguage {
        model.configuration.appLanguage
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                header
                statusCard

                TabView(selection: $selectedTab) {
                    buildTab
                        .tabItem { Text(AppStrings.buildTabTitle(language)) }
                        .tag(Tab.build)

                    customTab
                        .tabItem { Text(AppStrings.customTabTitle(language)) }
                        .tag(Tab.custom)
                }
            }
            .padding(20)
        }
        .frame(width: 440, height: 430)
        .onAppear { model.refreshInstalledInfo() }
        .confirmationDialog(
            AppStrings.removeConfirmTitle(language),
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button(AppStrings.removeConfirmButton(language), role: .destructive) {
                model.run(step: .removePrevious)
            }
            Button(AppStrings.cancelButton(language), role: .cancel) {}
        } message: {
            Text(AppStrings.removeConfirmMessage(language))
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.28), lineWidth: 1)

                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(8)
            }
            .frame(width: 54, height: 54)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.18 : 0.08), radius: 12, y: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text("VoodooHDA Builder")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text(AppStrings.subtitle(language))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Picker(AppStrings.languageLabel(language), selection: Binding(get: {
                model.configuration.appLanguage
            }, set: { model.updateLanguage($0) })) {
                ForEach(AppLanguage.allCases) { appLanguage in
                    Text(appLanguage.pickerTitle).tag(appLanguage)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 104)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppStrings.statusLabel(language))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text(model.progressLine)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Text(model.isRunning ? AppStrings.runningBadge(language) : AppStrings.readyBadge(language))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(statusBadgeForeground)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(statusBadgeBackground, in: Capsule())
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08))
                        .frame(height: 10)

                    Capsule()
                        .fill(progressGradient)
                        .frame(width: max(12, proxy.size.width * model.progressValue), height: 10)
                }
            }
            .frame(height: 10)

            Divider().opacity(0.4)

            installedRow
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.22), lineWidth: 1)
        )
    }

    private var installedRow: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(model.installedInfo.isInstalled ? Color(red: 0.19, green: 0.72, blue: 0.48) : Color.secondary.opacity(0.5))
                .frame(width: 7, height: 7)

            Text(AppStrings.installedSummary(
                kext: model.installedInfo.kext?.version,
                prefPane: model.installedInfo.prefPane?.version,
                language: language
            ))
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)

            Spacer(minLength: 4)

            Button {
                model.refreshInstalledInfo()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.borderless)
            .help(AppStrings.refreshInstalledTooltip(language))
        }
    }

    private var buildTab: some View {
        VStack(spacing: 10) {
            Button(model.isRunning ? AppStrings.processingButton(language) : AppStrings.buildButton(language)) {
                model.runAll()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(nsColor: .controlAccentColor))
            .disabled(model.isRunning)
            .controlSize(.large)
            .frame(maxWidth: .infinity)

            Text(AppStrings.autoOpenNote(language))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button(AppStrings.removeVoodooButton(language)) {
                showRemoveConfirmation = true
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.small)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .disabled(model.isRunning)
        }
        .padding(14)
    }

    private var customTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            BundleDropField(
                label: AppStrings.customKextFieldLabel(language),
                path: model.configuration.customKextPath,
                placeholder: AppStrings.nothingSelected(language),
                allowedExtension: "kext",
                chooseTitle: AppStrings.chooseButton(language),
                dropHint: AppStrings.dropHint(fileExtension: "kext", language: language),
                isDisabled: model.isRunning,
                onSelect: { model.updateCustomKextPath($0) }
            )

            BundleDropField(
                label: AppStrings.customPrefPaneFieldLabel(language),
                path: model.configuration.customPrefPanePath,
                placeholder: AppStrings.templatePrefPaneFallback(language),
                allowedExtension: "prefPane",
                chooseTitle: AppStrings.chooseButton(language),
                dropHint: AppStrings.dropHint(fileExtension: "prefPane", language: language),
                isDisabled: model.isRunning,
                onSelect: { model.updateCustomPrefPanePath($0) }
            )

            Text(AppStrings.customOutputNote(path: model.customOutputDirectory, language: language))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button(model.isRunning ? AppStrings.processingButton(language) : AppStrings.customPackageButton(language)) {
                model.run(step: .packageCustomKext)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(nsColor: .controlAccentColor))
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(model.isRunning || model.configuration.customKextPath.isEmpty)
        }
        .padding(14)
    }

    private var backgroundGradient: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.10, green: 0.12, blue: 0.16),
                Color(red: 0.14, green: 0.18, blue: 0.22),
                Color(red: 0.08, green: 0.10, blue: 0.13)
            ]
        }

        return [
            Color(red: 0.95, green: 0.97, blue: 0.99),
            Color(red: 0.90, green: 0.94, blue: 0.98),
            Color(red: 0.98, green: 0.96, blue: 0.92)
        ]
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.11, green: 0.55, blue: 0.95),
                Color(red: 0.09, green: 0.77, blue: 0.69)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var statusBadgeBackground: Color {
        model.isRunning
            ? Color(red: 0.98, green: 0.73, blue: 0.24)
            : Color(red: 0.19, green: 0.72, blue: 0.48)
    }

    private var statusBadgeForeground: Color {
        model.isRunning ? .black : .white
    }
}

private struct BundleDropField: View {
    let label: String
    let path: String
    let placeholder: String
    let allowedExtension: String
    let chooseTitle: String
    let dropHint: String
    let isDisabled: Bool
    let onSelect: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: isTargeted ? "arrow.down.doc.fill" : (path.isEmpty ? "tray.and.arrow.down" : "shippingbox.fill"))
                        .font(.system(size: 11))
                        .foregroundStyle(isTargeted ? Color(nsColor: .controlAccentColor) : .secondary)

                    Text(fieldText)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(path.isEmpty ? Color.secondary : Color.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(fieldBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(
                            isTargeted ? Color(nsColor: .controlAccentColor) : Color.clear,
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                        )
                )
                .help(path.isEmpty ? dropHint : path)
                .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)

                Button(chooseTitle) {
                    if let selected = chooseBundle() {
                        onSelect(selected)
                    }
                }
                .controlSize(.small)
                .disabled(isDisabled)

                if !path.isEmpty {
                    Button {
                        onSelect("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .disabled(isDisabled)
                }
            }
        }
    }

    private var fieldText: String {
        if isTargeted { return dropHint }
        if path.isEmpty { return "\(placeholder) — \(dropHint)" }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    private var fieldBackground: Color {
        if isTargeted {
            return Color(nsColor: .controlAccentColor).opacity(0.18)
        }
        return Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.06)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard !isDisabled, let provider = providers.first else { return false }

        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard
                let url,
                url.isFileURL,
                url.pathExtension.caseInsensitiveCompare(allowedExtension) == .orderedSame,
                FileManager.default.fileExists(atPath: url.path)
            else {
                return
            }

            DispatchQueue.main.async {
                onSelect(url.path)
            }
        }

        return true
    }

    private func chooseBundle() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = false
        panel.prompt = chooseTitle

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        guard url.pathExtension.caseInsensitiveCompare(allowedExtension) == .orderedSame else { return nil }
        return url.path
    }
}
