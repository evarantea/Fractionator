import SwiftUI

@main
struct FractionatorApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(model)
                .tint(.accentColor)
        }
    }
}
