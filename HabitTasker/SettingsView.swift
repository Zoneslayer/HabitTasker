import SwiftUI
import UniformTypeIdentifiers

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
                    DatePicker(
                        "Время напоминаний",
                        selection: $notificationsSettings.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    Text("Пуши добавим в следующей версии. Сейчас это настройка-черновик.")
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
                    Text("HabitTasker v0.2.2.1")
                        .foregroundStyle(AppPalette.textSecondary)
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
            alert.makeAlert(store: store)
        }
    }

    private var appVersion: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
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
}

private enum SettingsAlert: Identifiable {
    case reset
    case exportError(String)
    case importError(String)

    var id: String {
        switch self {
        case .reset:
            return "reset"
        case .exportError:
            return "exportError"
        case .importError:
            return "importError"
        }
    }

    func makeAlert(store: HabitStore) -> Alert {
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
        }
    }
}
