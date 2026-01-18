import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Сегодня", systemImage: "house.fill") }

            HabitsView()
                .tabItem { Label("Привычки", systemImage: "square.grid.2x2.fill") }

            StatsView()
                .tabItem { Label("Статистика", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape") }
        }
        .tint(Color(hex: "4DA3FF"))
        .background(AppPalette.background)
    }
}
