import SwiftUI

@main
struct HabitTaskerApp: App {
    @StateObject private var store = HabitStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark) // темная тема всегда
        }
    }
}

