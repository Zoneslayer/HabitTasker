import Foundation

enum DateUtils {

    static func startOfDay(_ d: Date) -> Date {
        Calendar.current.startOfDay(for: d)
    }

    /// Ключ дня в формате YYYY-MM-DD
    static func dayKey(_ d: Date) -> String {
        let d0 = startOfDay(d)
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: d0)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let day = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, day)
    }

    static func date(from key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2]) else { return nil }
        var comps = DateComponents()
        comps.year = y
        comps.month = m
        comps.day = d
        return Calendar.current.date(from: comps).map { startOfDay($0) }
    }

    /// Последние N дней, включая endingAt. Возвращает по возрастанию (старые -> новые).
    static func lastDays(count: Int, endingAt end: Date) -> [Date] {
        let end0 = startOfDay(end)
        return (0..<count).reversed().compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: end0)
        }
    }

    /// Совместимость с прошлым названием.
    static func lastDays(_ count: Int, from base: Date) -> [Date] {
        lastDays(count: count, endingAt: base)
    }

    // MARK: - Compatibility helpers (старые имена из прошлых итераций)

    static func last7Days(to endDate: Date = Date()) -> [Date] {
        lastDays(count: 7, endingAt: endDate)
    }

    static func last30Days(to endDate: Date = Date()) -> [Date] {
        lastDays(count: 30, endingAt: endDate)
    }

    static func last365Days(to endDate: Date = Date()) -> [Date] {
        lastDays(count: 365, endingAt: endDate)
    }

    static func weekdayLetterRu(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "EEEEE" // одна буква
        return df.string(from: date).uppercased()
    }

    static func weekdayLetter(_ date: Date) -> String {
        weekdayLetterRu(date)
    }

    static func date(fromDayKey key: String) -> Date? {
        date(from: key)
    }
}
