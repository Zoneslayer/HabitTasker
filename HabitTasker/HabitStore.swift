import Foundation
import Combine

@MainActor
final class HabitStore: ObservableObject {

    @Published var habits: [Habit] = [] {
        didSet { scheduleSave() }
    }

    @Published var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    private let persistence = PersistenceManager()
    private var saveTask: Task<Void, Never>?
    private let saveDelay: UInt64 = 800_000_000

    init() {
        loadFromDisk()
    }

    // MARK: - Day state

    func state(for habit: Habit, on date: Date) -> DayState {
        let key = DateUtils.dayKey(date)
        return habit.dayStates[key] ?? .none
    }

    func setState(for habitId: UUID, on date: Date, state: DayState) {
        guard let idx = habits.firstIndex(where: { $0.id == habitId }) else { return }
        let key = DateUtils.dayKey(date)
        var h = habits[idx]

        if state == .none {
            h.dayStates.removeValue(forKey: key)
        } else {
            h.dayStates[key] = state
        }
        habits[idx] = h
    }

    func toggleDone(for habitId: UUID, on date: Date) {
        guard let idx = habits.firstIndex(where: { $0.id == habitId }) else { return }
        let key = DateUtils.dayKey(date)
        var h = habits[idx]

        let current = h.dayStates[key] ?? .none
        let next: DayState = (current == .done) ? .none : .done

        if next == .none {
            h.dayStates.removeValue(forKey: key)
        } else {
            h.dayStates[key] = next
        }

        habits[idx] = h
    }

    /// Цикл по состояниям: none → done → skip → fail → none
    func cycleState(for habitId: UUID, on date: Date) {
        guard let idx = habits.firstIndex(where: { $0.id == habitId }) else { return }
        let key = DateUtils.dayKey(date)
        var h = habits[idx]

        let current = h.dayStates[key] ?? .none
        let next: DayState
        switch current {
        case .none: next = .done
        case .done: next = .skip
        case .skip: next = .fail
        case .fail: next = .none
        }

        if next == .none {
            h.dayStates.removeValue(forKey: key)
        } else {
            h.dayStates[key] = next
        }

        habits[idx] = h
    }

    // MARK: - CRUD

    func deleteHabit(_ id: UUID) {
        habits.removeAll { $0.id == id }
    }

    // MARK: - Streaks

    /// Текущий стрик (подряд DONE) до указанной даты включительно.
    /// Любое состояние кроме .done (none/skip/fail) обрывает стрик.
    func currentStreak(for habit: Habit, until endDate: Date) -> Int {
        let calendar = Calendar.current
        var count = 0
        var d = startOfDay(endDate)

        while true {
            if state(for: habit, on: d) == .done {
                count += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: d) else { break }
                d = prev
            } else {
                break
            }
        }

        return count
    }

    /// Лучший стрик (максимальная серия DONE в истории).
    func bestStreak(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let dates = habit.dayStates.keys.compactMap { DateUtils.date(fromDayKey: $0) }.sorted()
        guard let minDate = dates.first, let maxDate = dates.last else { return 0 }

        var best = 0
        var current = 0

        var d = startOfDay(minDate)
        let end = startOfDay(maxDate)

        while d <= end {
            if state(for: habit, on: d) == .done {
                current += 1
                if current > best { best = current }
            } else {
                current = 0
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }

        return best
    }

    // MARK: - Persistence

    func exportJSON() throws -> URL {
        let snapshot = AppSnapshot(schemaVersion: PersistenceManager.schemaVersion, habits: habits)
        let data = try persistence.encode(snapshot: snapshot)
        let filename = "HabitTasker-\(DateUtils.dayKey(Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: [.atomic])
        return url
    }

    func importJSON(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let snapshot = try persistence.decode(data: data)
        habits = snapshot.habits
        persistNow(habits: snapshot.habits)
    }

    func resetData() {
        habits = []
        persistNow(habits: [])
    }

    private func loadFromDisk() {
        do {
            if let snapshot = try persistence.load() {
                habits = snapshot.habits
                return
            }
            seedHabits()
            persistNow(habits: habits)
        } catch {
            print("Failed to load habits data: \(error)")
            habits = []
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshotHabits = habits
        let delay = saveDelay
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            await self?.persistNow(habits: snapshotHabits)
        }
    }

    private func persistNow(habits: [Habit]) {
        let snapshot = AppSnapshot(schemaVersion: PersistenceManager.schemaVersion, habits: habits)
        do {
            try persistence.save(snapshot: snapshot)
        } catch {
            print("Failed to save habits data: \(error)")
        }
    }

    private func seedHabits() {
        habits = [
            Habit(name: "Без сахара", icon: "🍬", colorHex: "F4D8D1"),
            Habit(name: "Без алкоголя", icon: "🍺", colorHex: "FFB84D"),
            Habit(name: "Прогулка 20 мин", icon: "🚶‍♂️", colorHex: "4DFFB8"),
            Habit(name: "Вода 2 литра", icon: "💧", colorHex: "4DA3FF"),
            Habit(name: "Чтение 30 мин", icon: "📚", colorHex: "B84DFF")
        ]
    }

    private func startOfDay(_ d: Date) -> Date {
        Calendar.current.startOfDay(for: d)
    }
}
