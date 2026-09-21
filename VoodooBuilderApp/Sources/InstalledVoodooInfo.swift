import Foundation

struct InstalledComponent: Equatable {
    let version: String
    let path: String
}

struct InstalledVoodooInfo: Equatable {
    var kext: InstalledComponent?
    var prefPane: InstalledComponent?

    static let empty = InstalledVoodooInfo(kext: nil, prefPane: nil)

    var isInstalled: Bool {
        kext != nil || prefPane != nil
    }

    static func current() -> InstalledVoodooInfo {
        InstalledVoodooInfo(
            kext: firstAvailable(in: kextSearchPaths),
            prefPane: firstAvailable(in: prefPaneSearchPaths)
        )
    }

    /// Le CFBundleShortVersionString (ou CFBundleVersion) de um bundle .kext/.prefPane.
    static func bundleVersion(atBundlePath path: String) -> String? {
        let infoPlistURL = URL(fileURLWithPath: path, isDirectory: true)
            .appendingPathComponent("Contents/Info.plist")

        guard
            let data = try? Data(contentsOf: infoPlistURL),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return nil
        }

        let short = (plist["CFBundleShortVersionString"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let build = (plist["CFBundleVersion"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let short, !short.isEmpty { return short }
        if let build, !build.isEmpty { return build }
        return nil
    }

    private static var kextSearchPaths: [String] {
        [
            "/Library/Extensions/VoodooHDA.kext",
            "/System/Library/Extensions/VoodooHDA.kext"
        ]
    }

    private static var prefPaneSearchPaths: [String] {
        [
            NSHomeDirectory() + "/Library/PreferencePanes/VoodooHDA.prefPane",
            "/Library/PreferencePanes/VoodooHDA.prefPane"
        ]
    }

    private static func firstAvailable(in paths: [String]) -> InstalledComponent? {
        for path in paths {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            let version = bundleVersion(atBundlePath: path) ?? "?"
            return InstalledComponent(version: version, path: path)
        }
        return nil
    }
}
