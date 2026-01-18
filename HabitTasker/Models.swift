import Foundation

enum DayState: String, Codable, Hashable {
    case none
    case done
    case skip
    case fail
}

struct Habit: Identifiable, Codable, Equatable {
    var id: UUID = UUID()

    var name: String
    var icon: String
    var colorHex: String

    /// Состояния по дням, ключ: "yyyy-MM-dd"
    var dayStates: [String: DayState] = [:]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        dayStates: [String: DayState] = [:]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.dayStates = dayStates
    }
}

