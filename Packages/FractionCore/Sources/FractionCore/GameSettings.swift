import Foundation

public struct GameSettings: Codable, Equatable, Sendable {
    public static let durationOptions = [30, 60, 120, 300]
    public static let rangeLimit = 1...99

    public var durationSeconds: Int
    public var enabledKinds: Set<ProblemKind>
    public var numeratorMin: Int
    public var numeratorMax: Int
    public var denominatorMin: Int
    public var denominatorMax: Int
    /// Operands always have numerator < denominator.
    public var properFractionsOnly: Bool
    /// Fraction answers must be typed in lowest terms (6/8 is rejected for 3/4).
    public var requireLowestTerms: Bool
    /// Fraction → decimal may use denominators like 3 or 7, answered rounded to 3 places.
    public var includeRepeatingDecimals: Bool
    /// Subtraction may give negative answers (3/4 − 5/6 = −1/12).
    public var allowNegativeAnswers: Bool

    public static let defaultKinds: Set<ProblemKind> = [
        .addition, .subtraction, .multiplication, .division,
        .power, .oneMinusPower, .simplify, .fractionToDecimal,
    ]

    public static let repeatingDecimalPlaces = 3

    public init(
        durationSeconds: Int = 120,
        enabledKinds: Set<ProblemKind> = GameSettings.defaultKinds,
        numeratorMin: Int = 1,
        numeratorMax: Int = 12,
        denominatorMin: Int = 2,
        denominatorMax: Int = 12,
        properFractionsOnly: Bool = true,
        requireLowestTerms: Bool = true,
        includeRepeatingDecimals: Bool = true,
        allowNegativeAnswers: Bool = true
    ) {
        self.durationSeconds = durationSeconds
        self.enabledKinds = enabledKinds
        self.numeratorMin = numeratorMin
        self.numeratorMax = numeratorMax
        self.denominatorMin = denominatorMin
        self.denominatorMax = denominatorMax
        self.properFractionsOnly = properFractionsOnly
        self.requireLowestTerms = requireLowestTerms
        self.includeRepeatingDecimals = includeRepeatingDecimals
        self.allowNegativeAnswers = allowNegativeAnswers
    }

    /// Settings forced into a playable state: ranges ordered and in bounds, at least one kind enabled.
    public func sanitized() -> GameSettings {
        var s = self
        let lim = GameSettings.rangeLimit
        s.numeratorMin = min(max(s.numeratorMin, lim.lowerBound), lim.upperBound)
        s.numeratorMax = min(max(s.numeratorMax, s.numeratorMin), lim.upperBound)
        s.denominatorMin = min(max(s.denominatorMin, lim.lowerBound), lim.upperBound)
        s.denominatorMax = min(max(s.denominatorMax, s.denominatorMin), lim.upperBound)
        if !GameSettings.durationOptions.contains(s.durationSeconds) {
            s.durationSeconds = 120
        }
        if s.enabledKinds.isEmpty {
            s.enabledKinds = [.addition]
        }
        return s
    }

    /// Stable identifier for "same game": runs with equal keys are compared for best scores.
    public var key: String {
        let kinds = ProblemKind.allCases.filter(enabledKinds.contains).map(\.rawValue).joined(separator: ",")
        return [
            "t\(durationSeconds)",
            kinds,
            "n\(numeratorMin)-\(numeratorMax)",
            "d\(denominatorMin)-\(denominatorMax)",
            properFractionsOnly ? "p1" : "p0",
            requireLowestTerms ? "l1" : "l0",
            includeRepeatingDecimals ? "r1" : "r0",
            allowNegativeAnswers ? "m1" : "m0",
        ].joined(separator: "|")
    }

    /// Short human-readable description, e.g. "2 min · + − × ÷ · n 1–12 · d 2–12".
    public var summary: String {
        let kinds = ProblemKind.allCases.filter(enabledKinds.contains).map(\.shortTitle).joined(separator: " ")
        let time = durationSeconds % 60 == 0 ? "\(durationSeconds / 60) min" : "\(durationSeconds)s"
        var parts = [time, kinds]
        if enabledKinds.contains(where: \.usesNumeratorRange) {
            parts.append("n \(numeratorMin)–\(numeratorMax)")
        }
        parts.append("d \(denominatorMin)–\(denominatorMax)")
        return parts.joined(separator: " · ")
    }

    // Decoding tolerates missing keys so stored settings survive new options in later versions.
    private enum CodingKeys: String, CodingKey {
        case durationSeconds, enabledKinds, numeratorMin, numeratorMax, denominatorMin, denominatorMax
        case properFractionsOnly, requireLowestTerms, includeRepeatingDecimals, allowNegativeAnswers
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GameSettings()
        durationSeconds = try c.decodeIfPresent(Int.self, forKey: .durationSeconds) ?? d.durationSeconds
        // Unknown kinds from a newer version are dropped rather than failing the decode.
        let rawKinds = try c.decodeIfPresent([String].self, forKey: .enabledKinds)
        enabledKinds = rawKinds.map { Set($0.compactMap(ProblemKind.init(rawValue:))) } ?? d.enabledKinds
        numeratorMin = try c.decodeIfPresent(Int.self, forKey: .numeratorMin) ?? d.numeratorMin
        numeratorMax = try c.decodeIfPresent(Int.self, forKey: .numeratorMax) ?? d.numeratorMax
        denominatorMin = try c.decodeIfPresent(Int.self, forKey: .denominatorMin) ?? d.denominatorMin
        denominatorMax = try c.decodeIfPresent(Int.self, forKey: .denominatorMax) ?? d.denominatorMax
        properFractionsOnly = try c.decodeIfPresent(Bool.self, forKey: .properFractionsOnly) ?? d.properFractionsOnly
        requireLowestTerms = try c.decodeIfPresent(Bool.self, forKey: .requireLowestTerms) ?? d.requireLowestTerms
        includeRepeatingDecimals = try c.decodeIfPresent(Bool.self, forKey: .includeRepeatingDecimals) ?? d.includeRepeatingDecimals
        allowNegativeAnswers = try c.decodeIfPresent(Bool.self, forKey: .allowNegativeAnswers) ?? d.allowNegativeAnswers
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(durationSeconds, forKey: .durationSeconds)
        try c.encode(ProblemKind.allCases.filter(enabledKinds.contains).map(\.rawValue), forKey: .enabledKinds)
        try c.encode(numeratorMin, forKey: .numeratorMin)
        try c.encode(numeratorMax, forKey: .numeratorMax)
        try c.encode(denominatorMin, forKey: .denominatorMin)
        try c.encode(denominatorMax, forKey: .denominatorMax)
        try c.encode(properFractionsOnly, forKey: .properFractionsOnly)
        try c.encode(requireLowestTerms, forKey: .requireLowestTerms)
        try c.encode(includeRepeatingDecimals, forKey: .includeRepeatingDecimals)
        try c.encode(allowNegativeAnswers, forKey: .allowNegativeAnswers)
    }
}
