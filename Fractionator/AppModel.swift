import Foundation
import FractionCore

/// Settings and run history, both kept only on this device.
@MainActor
final class AppModel: ObservableObject {
    private static let settingsKey = "settings.v1"

    @Published var settings: GameSettings {
        didSet { saveSettings() }
    }

    /// Newest first.
    @Published private(set) var history: [RunRecord] = []

    private let defaults: UserDefaults
    private let historyURL: URL

    init(defaults: UserDefaults = .standard, directory: URL? = nil) {
        self.defaults = defaults
        let dir = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        historyURL = dir.appendingPathComponent("history.json")

        if let data = defaults.data(forKey: Self.settingsKey),
           let saved = try? JSONDecoder().decode(GameSettings.self, from: data) {
            settings = saved.sanitized()
        } else {
            settings = GameSettings()
        }
        loadHistory()
    }

    func stats(for settings: GameSettings? = nil) -> HistoryStats {
        HistoryStats(records: history, settingsKey: settings?.key)
    }

    func add(_ record: RunRecord) {
        history.insert(record, at: 0)
        saveHistory()
    }

    func delete(ids: Set<UUID>) {
        history.removeAll { ids.contains($0.id) }
        saveHistory()
    }

    func clearHistory() {
        history = []
        saveHistory()
    }

    func resetSettings() {
        settings = GameSettings()
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.settingsKey)
        }
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        history = ((try? decoder.decode([RunRecord].self, from: data)) ?? [])
            .sorted { $0.date > $1.date }
    }

    private func saveHistory() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(history) else { return }
        try? data.write(to: historyURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
