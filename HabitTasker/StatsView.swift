import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: HabitStore

    enum Period: String, CaseIterable, Identifiable {
        case week = "Неделя"
        case month = "Месяц"
        case year = "Год"
        var id: String { rawValue }
    }

    @State private var period: Period = .month

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {

                        Text("Статистика")
                            .font(.largeTitle.weight(.bold))
                            .padding(.horizontal)
                            .padding(.top, 10)

                        // сегмент
                        Picker("", selection: $period) {
                            ForEach(Period.allCases) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        // сводка
                        SummaryCard(
                            title: "Сводка",
                            subtitle: summaryLine,
                            periodText: periodText
                        )
                        .padding(.horizontal)

                        // карточки привычек
                        VStack(spacing: 10) {
                            ForEach(store.habits) { h in
                                habitStatCard(h)
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 24)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Summary

    private var summaryLine: String {
        let range = selectedRange()
        let total = store.habits.count * range.days.count
        if total == 0 { return "Нет данных" }

        let done = doneCountAll(range: range)
        let pct = Int((Double(done) / Double(total)) * 100.0)

        return "\(done) выполнено из \(total) • \(pct)%"
    }

    private var periodText: String {
        let range = selectedRange()
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateStyle = .medium
        return "Период: \(df.string(from: range.start)) — \(df.string(from: range.end))"
    }

    // MARK: - Habit cards

    @ViewBuilder
    private func habitStatCard(_ h: Habit) -> some View {
        let range = selectedRange()
        let total = range.days.count
        let done = doneCount(for: h, range: range)
        let pct = total == 0 ? 0 : Int((Double(done) / Double(total)) * 100.0)

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
                    Text("\(done)/\(total) • \(pct)%")
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                Spacer()

                Circle()
                    .fill(Color(hex: h.colorHex))
                    .frame(width: 10, height: 10)
            }

            // мини "heatmap" 7x? не делаем — MVP: последняя неделя кружками
            // чтобы было аккуратно как у тебя — показываем последние 14 дней точками
            let dots = lastNDays(14)
            HStack(spacing: 8) {
                ForEach(dots, id: \.self) { d in
                    let s = store.state(for: h, on: d)
                    Circle()
                        .fill(dotFill(state: s, colorHex: h.colorHex))
                        .frame(width: 10, height: 10)
                        .opacity(s == .done ? 1.0 : 0.25)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: h.colorHex).opacity(0.55), lineWidth: 1)
                )
        )
    }

    private func dotFill(state: DayState, colorHex: String) -> Color {
        switch state {
        case .done:
            return Color(hex: colorHex)
        case .skip:
            return AppPalette.textSecondary.opacity(0.55)
        case .fail:
            return Color.red.opacity(0.75)
        case .none:
            return AppPalette.textSecondary
        }
    }


    // MARK: - Date ranges (без DateUtils и без from:)

    private func selectedRange() -> (start: Date, end: Date, days: [Date]) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        switch period {
        case .week:
            // последние 7 дней включая сегодня
            let start = cal.date(byAdding: .day, value: -6, to: today)!
            let days = makeDays(from: start, toInclusive: today)
            return (start, today, days)

        case .month:
            // последние 30 дней включая сегодня
            let start = cal.date(byAdding: .day, value: -29, to: today)!
            let days = makeDays(from: start, toInclusive: today)
            return (start, today, days)

        case .year:
            // последние 365 дней включая сегодня
            let start = cal.date(byAdding: .day, value: -364, to: today)!
            let days = makeDays(from: start, toInclusive: today)
            return (start, today, days)
        }
    }

    private func makeDays(from start: Date, toInclusive end: Date) -> [Date] {
        let cal = Calendar.current
        var days: [Date] = []
        var cur = cal.startOfDay(for: start)
        let last = cal.startOfDay(for: end)
        while cur <= last {
            days.append(cur)
            cur = cal.date(byAdding: .day, value: 1, to: cur)!
        }
        return days
    }

    private func lastNDays(_ n: Int) -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -(n - 1), to: today)!
        return makeDays(from: start, toInclusive: today)
    }

    // MARK: - Counting

    private func doneCountAll(range: (start: Date, end: Date, days: [Date])) -> Int {
        var sum = 0
        for h in store.habits {
            sum += doneCount(for: h, range: range)
        }
        return sum
    }

    private func doneCount(for habit: Habit, range: (start: Date, end: Date, days: [Date])) -> Int {
        range.days.reduce(0) { acc, d in
            acc + (store.state(for: habit, on: d) == .done ? 1 : 0)
        }
    }
}

// MARK: - Small UI

private struct SummaryCard: View {
    let title: String
    let subtitle: String
    let periodText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppPalette.textSecondary)
            Text(periodText)
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppPalette.card)
        )
    }
}

