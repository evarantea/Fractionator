import Foundation

/// One timed run. The UI owns the clock; the engine owns problems, input and score.
public struct GameEngine: Sendable {
    public enum Key: Equatable, Sendable {
        case digit(Int)
        case slash
        case point
        case delete
        case clear
    }

    public static let maxInputLength = 12

    public let settings: GameSettings
    public private(set) var current: Problem
    public private(set) var input: String = ""
    public private(set) var score = 0
    public private(set) var skips = 0
    public private(set) var correctByKind: [ProblemKind: Int] = [:]
    /// Problems the player skipped, kept so the results screen can show the answers.
    public private(set) var skipped: [Problem] = []

    private var generator: ProblemGenerator

    public init(settings: GameSettings, rng: SplitMix64 = SplitMix64()) {
        var generator = ProblemGenerator(settings: settings, rng: rng)
        self.settings = generator.settings
        self.current = generator.next()
        self.generator = generator
    }

    /// Applies a key press. Returns true when the input became a correct answer,
    /// in which case the score went up and the next problem is already showing.
    @discardableResult
    public mutating func press(_ key: Key) -> Bool {
        switch key {
        case .digit(let d):
            guard (0...9).contains(d), input.count < GameEngine.maxInputLength else { return false }
            input.append(String(d))
        case .slash:
            guard current.answerFormat == .fraction,
                  !input.isEmpty, !input.contains("/"), !input.contains(".")
            else { return false }
            input.append("/")
        case .point:
            guard current.answerFormat == .decimal,
                  !input.contains("."), !input.contains("/"),
                  input.count < GameEngine.maxInputLength
            else { return false }
            input.append(input.isEmpty ? "0." : ".")
        case .delete:
            if !input.isEmpty { input.removeLast() }
            return false
        case .clear:
            input = ""
            return false
        }
        return checkAnswer()
    }

    public mutating func skip() {
        skips += 1
        skipped.append(current)
        advance()
    }

    public func record(date: Date = Date()) -> RunRecord {
        RunRecord(
            date: date,
            score: score,
            skips: skips,
            durationSeconds: settings.durationSeconds,
            settingsKey: settings.key,
            settingsSummary: settings.summary,
            correctByKind: Dictionary(uniqueKeysWithValues: correctByKind.map { ($0.key.rawValue, $0.value) })
        )
    }

    private mutating func checkAnswer() -> Bool {
        guard current.isCorrect(input, requireLowestTerms: settings.requireLowestTerms) else { return false }
        score += 1
        correctByKind[current.kind, default: 0] += 1
        advance()
        return true
    }

    private mutating func advance() {
        input = ""
        current = generator.next()
    }
}
