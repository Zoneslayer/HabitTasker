import Foundation

struct AppSnapshot: Codable {
    let schemaVersion: Int
    var habits: [Habit]
}

enum PersistenceError: LocalizedError {
    case invalidSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case .invalidSchemaVersion(let version):
            return "Неподдерживаемая версия данных: \(version)."
        }
    }
}

struct PersistenceManager {
    static let schemaVersion = 1

    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directoryURL = baseURL.appendingPathComponent("HabitTasker", isDirectory: true)
        self.fileURL = directoryURL.appendingPathComponent("habits.json")
    }

    func load() throws -> AppSnapshot? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        return try decode(data: data)
    }

    func save(snapshot: AppSnapshot) throws {
        let data = try encode(snapshot: snapshot)
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: [.atomic])
    }

    func encode(snapshot: AppSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snapshot)
    }

    func decode(data: Data) throws -> AppSnapshot {
        let decoder = JSONDecoder()
        let snapshot = try decoder.decode(AppSnapshot.self, from: data)
        guard snapshot.schemaVersion == Self.schemaVersion else {
            throw PersistenceError.invalidSchemaVersion(snapshot.schemaVersion)
        }
        return snapshot
    }
}
