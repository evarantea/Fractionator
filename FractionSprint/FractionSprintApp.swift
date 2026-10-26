import SwiftUI

@main
struct FractionSprintApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(model)
                .tint(.accentColor)
        }
    }
}
