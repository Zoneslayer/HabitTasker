import Foundation
import UIKit
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleDailyReminder(at time: Date, id: String = "daily_reminder") {
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "HabitTasker"
        content.body = "Пора закрыть привычки на сегодня 👌"
        content.sound = .default

        let dateComponents = NotificationManager.dailyTimeComponents(from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request)
    }

    func cancelDailyReminder(id: String = "daily_reminder") {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func scheduleTestReminder(in seconds: Int = 5, id: String = "test_reminder") {
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "HabitTasker"
        content.body = "Пора закрыть привычки на сегодня 👌"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request)
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }

    static func dailyTimeComponents(from date: Date, calendar: Calendar = .current) -> DateComponents {
        calendar.dateComponents([.hour, .minute], from: date)
    }
}
