import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: HabitStore
    @StateObject private var notificationsSettings = NotificationsSettings()

    @State private var shareURL: URL?
    @State private var showingShareSheet = false
    @State private var isImporting = false
    @State private var alert: SettingsAlert?

    var body: some View {
        NavigationStack {
            Form {
                Section("Напоминания") {
                    Toggle("Включить напоминания", isOn: $notificationsSettings.enableReminders)
                        .onChange(of: notificationsSettings.enableReminders) { _, isEnabled in
                            handleReminderToggleChange(isEnabled)
                        }
                    DatePicker(
                        "Время напоминаний",
                        selection: $notificationsSettings.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: notificationsSettings.reminderTime) { _, newTime in
                        handleReminderTimeChange(newTime)
                    }
                    Button("Тест уведомления (через 5 сек)") {
                        handleTestReminder()
                    }
                    Text("Ежедневное напоминание придет в выбранное время.")
                        .font(.footnote)
                        .foregroundStyle(AppPalette.textSecondary)
                }
                .listRowBackground(AppPalette.card)

                Section("Данные") {
                    Button("Экспорт данных (JSON)") {
                        exportData()
                    }
                    Button("Импорт данных (JSON)") {
                        isImporting = true
                    }
                    Button("Сбросить данные", role: .destructive) {
                        alert = .reset
                    }
                }
                .listRowBackground(AppPalette.card)

                Section("О приложении") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }
                .listRowBackground(AppPalette.card)
            }
            .scrollContentBackground(.hidden)
            .background(AppPalette.background)
            .navigationTitle("Настройки")
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: { shareURL = nil }) {
            if let shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
        .alert(item: $alert) { alert in
            alert.makeAlert(store: store, notificationManager: NotificationManager.shared)
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let shortVersion = info?["CFBundleShortVersionString"] as? String
        let buildVersion = info?["CFBundleVersion"] as? String
        guard let shortVersion, let buildVersion else { return "—" }
        return "\(shortVersion) (\(buildVersion))"
    }

    private func exportData() {
        do {
            shareURL = try store.exportJSON()
            showingShareSheet = true
        } catch {
            alert = .exportError(error.localizedDescription)
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try store.importJSON(from: url)
            } catch {
                alert = .importError(error.localizedDescription)
            }
        case .failure(let error):
            alert = .importError(error.localizedDescription)
        }
    }

    private func handleReminderToggleChange(_ isEnabled: Bool) {
        Task {
            if isEnabled {
                let granted = await NotificationManager.shared.requestAuthorization()
                if granted {
                    NotificationManager.shared.scheduleDailyReminder(at: notificationsSettings.reminderTime)
                } else {
                    notificationsSettings.enableReminders = false
                    alert = .notificationsPermission
                }
            } else {
                NotificationManager.shared.cancelDailyReminder()
            }
        }
    }

    private func handleReminderTimeChange(_ newTime: Date) {
        guard notificationsSettings.enableReminders else { return }
        Task {
            let status = await NotificationManager.shared.authorizationStatus()
            if isAuthorized(status) {
                NotificationManager.shared.scheduleDailyReminder(at: newTime)
            } else {
                notificationsSettings.enableReminders = false
                alert = .notificationsPermission
            }
        }
    }

    private func handleTestReminder() {
        Task {
            let status = await NotificationManager.shared.authorizationStatus()
            if isAuthorized(status) {
                NotificationManager.shared.scheduleTestReminder()
            } else {
                if notificationsSettings.enableReminders {
                    notificationsSettings.enableReminders = false
                }
                alert = .notificationsPermission
            }
        }
    }

    private func isAuthorized(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }
}

private enum SettingsAlert: Identifiable {
    case reset
    case exportError(String)
    case importError(String)
    case notificationsPermission

    var id: String {
        switch self {
        case .reset:
            return "reset"
        case .exportError:
            return "exportError"
        case .importError:
            return "importError"
        case .notificationsPermission:
            return "notificationsPermission"
        }
    }

    func makeAlert(store: HabitStore, notificationManager: NotificationManager) -> Alert {
        switch self {
        case .reset:
            return Alert(
                title: Text("Сбросить данные?"),
                message: Text("Все привычки и отметки будут удалены."),
                primaryButton: .destructive(Text("Сбросить")) {
                    store.resetData()
                },
                secondaryButton: .cancel(Text("Отмена"))
            )
        case .exportError(let message):
            return Alert(
                title: Text("Не удалось экспортировать"),
                message: Text(message),
                dismissButton: .default(Text("Ок"))
            )
        case .importError(let message):
            return Alert(
                title: Text("Не удалось импортировать"),
                message: Text(message),
                dismissButton: .default(Text("Ок"))
            )
        case .notificationsPermission:
            return Alert(
                title: Text("Нет доступа к уведомлениям"),
                message: Text("Разрешите уведомления в настройках, чтобы напоминания работали."),
                primaryButton: .default(Text("Открыть Настройки")) {
                    notificationManager.openAppSettings()
                },
                secondaryButton: .cancel(Text("Отмена"))
            )
        }
    }
}
