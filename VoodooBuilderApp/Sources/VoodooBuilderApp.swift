import SwiftUI

@main
struct VoodooBuilderApp: App {
    @StateObject private var model = BuildViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(width: 420, height: 320)
        }
        .windowResizability(.contentSize)
    }
}