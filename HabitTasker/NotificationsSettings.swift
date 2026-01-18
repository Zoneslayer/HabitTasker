import Foundation
import Combine

@MainActor
final class NotificationsSettings: ObservableObject {
    private enum Keys {
        static let enableReminders = "HabitTasker.notifications.enableReminders"
        static let reminderTimeSeconds = "HabitTasker.notifications.reminderTimeSeconds"
    }

    @Published var enableReminders: Bool {
        didSet {
            UserDefaults.standard.set(enableReminders, forKey: Keys.enableReminders)
        }
    }

    @Published var reminderTime: Date {
        didSet {
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let seconds = Double((components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60)
            UserDefaults.standard.set(seconds, forKey: Keys.reminderTimeSeconds)
        }
    }

    init() {
        let storedEnabled = UserDefaults.standard.bool(forKey: Keys.enableReminders)
        let storedSeconds = UserDefaults.standard.object(forKey: Keys.reminderTimeSeconds) as? Double
            ?? (19.0 * 3600 + 30.0 * 60)

        self.enableReminders = storedEnabled
        self.reminderTime = NotificationsSettings.dateFromSeconds(storedSeconds)
    }

    var reminderComponents: DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
    }

    private static func dateFromSeconds(_ seconds: Double) -> Date {
        let totalSeconds = max(0, seconds)
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let components = DateComponents(hour: hours, minute: minutes)
        return Calendar.current.date(from: components) ?? Date()
    }
}
