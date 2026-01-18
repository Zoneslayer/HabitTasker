import SwiftUI

struct WeekDotsView: View {
    @EnvironmentObject private var store: HabitStore

    let habit: Habit
    /// Обычно это startOfDay(сегодня). Используется для подсветки выбранного дня.
    let baseDate: Date

    private var days: [Date] {
        DateUtils.last7Days(to: baseDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                ForEach(days, id: \.self) { d in
                    Text(DateUtils.weekdayLetter(d))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppPalette.textSecondary.opacity(0.8))
                        .frame(width: 28)
                }
            }

            HStack(spacing: 14) {
                ForEach(days, id: \.self) { d in
                    dayButton(for: d)
                }
            }
        }
    }

    // MARK: - Day Button

    @ViewBuilder
    private func dayButton(for day: Date) -> some View {
        let d0 = DateUtils.startOfDay(day)
        let state = store.state(for: habit, on: d0)
        let isSelected = DateUtils.dayKey(d0) == DateUtils.dayKey(baseDate)

        Button {
            store.cycleState(for: habit.id, on: d0)
        } label: {
            ZStack {
                Circle()
                    .fill(dotFill(for: state))
                    .overlay(
                        Circle()
                            .stroke(isSelected ? AppPalette.todayRing : Color.clear, lineWidth: 2)
                    )
                    .frame(width: 28, height: 28)

                Text("\(Calendar.current.component(.day, from: d0))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(dotTextColor(for: state))
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { store.setState(for: habit.id, on: d0, state: .done) } label: {
                Label("Выполнено", systemImage: "checkmark.circle")
            }
            Button { store.setState(for: habit.id, on: d0, state: .skip) } label: {
                Label("Пропуск", systemImage: "pause.circle")
            }
            Button(role: .destructive) { store.setState(for: habit.id, on: d0, state: .fail) } label: {
                Label("Провал", systemImage: "xmark.circle")
            }
            Button(role: .destructive) { store.setState(for: habit.id, on: d0, state: .none) } label: {
                Label("Очистить", systemImage: "trash")
            }
        }
    }

    private func dotFill(for state: DayState) -> Color {
        switch state {
        case .none:
            return AppPalette.card2
        case .done:
            return Color.green
        case .skip:
            return Color.gray.opacity(0.65)
        case .fail:
            return Color.red.opacity(0.75)
        }
    }

    private func dotTextColor(for state: DayState) -> Color {
        switch state {
        case .none:
            return AppPalette.textSecondary
        case .done, .skip, .fail:
            return Color.white
        }
    }
}
