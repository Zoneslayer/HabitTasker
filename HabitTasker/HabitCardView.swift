import SwiftUI

struct HabitCardView: View {
    @EnvironmentObject private var store: HabitStore

    let habit: Habit
    let selectedDate: Date

    private var habitColor: Color {
        Color(hex: habit.colorHex)
    }

    private var isDoneTodayForSelected: Bool {
        store.state(for: habit, on: selectedDate) == .done
    }

    private var borderColor: Color {
        // Обводка чуть ярче, чем заливка
        habitColor.opacity(0.75)
    }

    private var fillGradient: LinearGradient {
        // Мягкая “ламповая” заливка, но минималистично
        LinearGradient(
            colors: [
                habitColor.opacity(0.10),
                habitColor.opacity(0.03),
                Color.white.opacity(0.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Верхняя строка: иконка + название + кружок выполнено
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    Text(habit.icon)
                        .font(.system(size: 22))
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 20, weight: .semibold))

                    HStack(spacing: 8) {
                        Text("Стрик: \(store.currentStreak(for: habit, until: selectedDate))")
                        Text("•")
                        Text("Рекорд: \(store.bestStreak(for: habit))")
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Большой кружок “выполнено/не выполнено” за выбранный день
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        store.toggleDone(for: habit.id, on: selectedDate)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: 2)
                            .frame(width: 30, height: 30)

                        if isDoneTodayForSelected {
                            Circle()
                                .fill(habitColor.opacity(0.85))
                                .frame(width: 30, height: 30)

                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.black.opacity(0.75))
                        }
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isDoneTodayForSelected ? "Снять отметку" : "Отметить")
            }

            // Недельная полоска (7 кружков)
            WeekDotsView(habit: habit, baseDate: selectedDate)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.04))

                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(fillGradient)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(borderColor, lineWidth: 1.5)
        )
    }
}
