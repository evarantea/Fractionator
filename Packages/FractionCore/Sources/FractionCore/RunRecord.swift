import Foundation

/// A finished run, as saved in on-device history.
public struct RunRecord: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var date: Date
    public var score: Int
    public var skips: Int
    public var durationSeconds: Int
    public var settingsKey: String
    public var settingsSummary: String
    /// Correct answers per `ProblemKind.rawValue`.
    public var correctByKind: [String: Int]

    public init(
        id: UUID = UUID(),
        date: Date,
        score: Int,
        skips: Int,
        durationSeconds: Int,
        settingsKey: String,
        settingsSummary: String,
        correctByKind: [String: Int] = [:]
    ) {
        self.id = id
        self.date = date
        self.score = score
        self.skips = skips
        self.durationSeconds = durationSeconds
        self.settingsKey = settingsKey
        self.settingsSummary = settingsSummary
        self.correctByKind = correctByKind
    }

    /// Average seconds per correct answer, or nil with no correct answers.
    public var secondsPerAnswer: Double? {
        score > 0 ? Double(durationSeconds) / Double(score) : nil
    }
}

public struct HistoryStats: Equatable, Sendable {
    public let runs: Int
    public let best: Int?
    public let average: Double?
    /// Average of the last 10 runs.
    public let recentAverage: Double?

    /// Stats over `records` (any order) matching `settingsKey`, or over all records when nil.
    public init(records: [RunRecord], settingsKey: String? = nil) {
        let matching = records
            .filter { settingsKey == nil || $0.settingsKey == settingsKey }
            .sorted { $0.date > $1.date }
        runs = matching.count
        best = matching.map(\.score).max()
        average = matching.isEmpty ? nil : Double(matching.map(\.score).reduce(0, +)) / Double(matching.count)
        let recent = matching.prefix(10)
        recentAverage = recent.isEmpty ? nil : Double(recent.map(\.score).reduce(0, +)) / Double(recent.count)
    }
}
