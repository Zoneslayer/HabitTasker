import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: HabitStore
    @Environment(\.editMode) private var editMode

    @State private var editHabit: Habit? = nil

    // MARK: - Date

    private var today: Date {
        startOfDay(Date())
    }

    private var selectedDay: Date {
        startOfDay(store.selectedDate)
    }

    private var isViewingToday: Bool {
        Calendar.current.isDate(selectedDay, inSameDayAs: today)
    }

    // MARK: - Greeting

    private var greetingTitle: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Доброе утро ☀️"
        case 12..<18: return "Добрый день 🌤️"
        case 18..<23: return "Добрый вечер 🌙"
        default: return "Доброй ночи 🌚"
        }
    }

    private var greetingSubtitle: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateStyle = .long
        return df.string(from: selectedDay)
    }

    private var todayProgressText: String {
        let total = store.habits.count
        let done = store.habits.filter { h in
            store.state(for: h, on: selectedDay) == .done
        }.count

        let prefix = isViewingToday ? "Сегодня" : "В этот день"
        return "\(prefix): \(done)/\(total) выполнено"
    }

    // MARK: - UI

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {

                        header

                        // Прогресс дня
                        Text(todayProgressText)
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary.opacity(0.8))
                            .padding(.horizontal)

                        VStack(spacing: 10) {
                            ForEach(store.habits) { h in
                                habitCard(h)
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 24)
                    }
                }
            }
            .navigationTitle("Сегодня")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toggleEditMode()
                    } label: {
                        Text(isEditing ? "Готово" : "Правка")
                    }
                }
            }
            .sheet(item: $editHabit) { h in
                AddEditHabitView(mode: .edit(h))
                    .environmentObject(store)
            }
            .onAppear {
                // По умолчанию всегда открываем "сегодня"
                store.selectedDate = today
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(greetingTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppPalette.textSecondary)

                    // Если выбран НЕ сегодня — подсказка "просмотр даты"
                    if !isViewingToday {
                        Text("• просмотр")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppPalette.textSecondary.opacity(0.75))
                    }
                }

                Text(greetingSubtitle)
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary.opacity(0.8))
            }

            Spacer()

            // Явный возврат на сегодня, если “улетел” на другую дату
            if !isViewingToday {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        store.selectedDate = today
                    }
                } label: {
                    Text("Сегодня")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(AppPalette.card2))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Card

    @ViewBuilder
    private func habitCard(_ h: Habit) -> some View {
        let state = store.state(for: h, on: selectedDay)
        let streak = store.currentStreak(for: h, until: selectedDay)
        let best = store.bestStreak(for: h)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(h.icon)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppPalette.card2)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(h.name)
                        .font(.headline)

                    Text("Стрик: \(streak) • Рекорд: \(best)")
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                Spacer()

                // Кнопка отметки для выбранного дня
                Button {
                    store.toggleDone(for: h.id, on: selectedDay)
                } label: {
                    Image(systemName: state == .done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(state == .done ? Color.green : Color.secondary)
                        .frame(width: 54, height: 54)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isEditing {
                    Button {
                        editHabit = h
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(AppPalette.card2))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().opacity(0.3)

            // 7 дней вокруг выбранной даты (а не только “вокруг сегодня”)
            WeekDotsView(habit: h, baseDate: selectedDay)
                .environmentObject(store)
        }
        .padding()
        .background(cardBackground(colorHex: h.colorHex))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            // В режиме правки не отмечаем, чтобы не бесило
            if !isEditing {
                store.toggleDone(for: h.id, on: selectedDay)
            }
        }
    }

    private func cardBackground(colorHex: String) -> some View {
        let c = Color(hex: colorHex)
        return RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(AppPalette.card)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(c.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(c.opacity(0.55), lineWidth: 1)
            )
    }

    // MARK: - Helpers

    private var isEditing: Bool { editMode?.wrappedValue.isEditing == true }

    private func startOfDay(_ d: Date) -> Date {
        Calendar.current.startOfDay(for: d)
    }

    private func toggleEditMode() {
        if isEditing {
            editMode?.wrappedValue = .inactive
        } else {
            editMode?.wrappedValue = .active
        }
    }
}

