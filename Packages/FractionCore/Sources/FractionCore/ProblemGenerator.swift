import Foundation

/// Small, fast, seedable RNG so tests are deterministic.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public init() {
        var system = SystemRandomNumberGenerator()
        state = system.next()
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

public struct ProblemGenerator: Sendable {
    public let settings: GameSettings
    private var rng: SplitMix64
    private var last: Problem?

    /// Denominators used when the configured range has none that give a terminating decimal.
    static let fallbackTerminatingDenominators = [2, 4, 5, 8]

    public init(settings: GameSettings, rng: SplitMix64 = SplitMix64()) {
        self.settings = settings.sanitized()
        self.rng = rng
    }

    public mutating func next() -> Problem {
        // Avoid showing the same problem twice in a row; give up after a few tries on tiny ranges.
        var problem = makeProblem()
        var tries = 0
        while problem == last && tries < 10 {
            problem = makeProblem()
            tries += 1
        }
        last = problem
        return problem
    }

    private mutating func makeProblem() -> Problem {
        let kinds = ProblemKind.allCases.filter(settings.enabledKinds.contains)
        let kind = kinds.randomElement(using: &rng) ?? .addition

        switch kind {
        case .addition:
            let a = operand(), b = operand()
            return Problem(kind: kind, left: a, right: b, answer: a + b)

        case .subtraction:
            // Keep answers positive, like zetamac's subtraction (reverse of addition).
            var a = operand(), b = operand()
            var tries = 0
            while a == b && tries < 10 {
                b = operand()
                tries += 1
            }
            if a < b { swap(&a, &b) }
            return Problem(kind: kind, left: a, right: b, answer: a - b)

        case .multiplication:
            let a = operand(), b = operand()
            return Problem(kind: kind, left: a, right: b, answer: a * b)

        case .division:
            let a = operand(), b = operand()
            return Problem(kind: kind, left: a, right: b, answer: a / b)

        case .fractionToDecimal:
            let f = conversionFraction(allowRepeating: settings.includeRepeatingDecimals)
            if f.hasTerminatingDecimal {
                return Problem(kind: kind, left: f, answer: f)
            }
            let places = GameSettings.repeatingDecimalPlaces
            return Problem(kind: kind, left: f, answer: f.rounded(toPlaces: places), roundedPlaces: places)

        case .decimalToFraction:
            let f = conversionFraction(allowRepeating: false)
            return Problem(kind: kind, left: f, answer: f)
        }
    }

    /// A random operand from the configured ranges, in lowest terms, never zero,
    /// and not a whole number unless the ranges make that unavoidable.
    private mutating func operand() -> Fraction {
        var result = rawOperand()
        var tries = 0
        while result.isWhole && settings.denominatorMax > 1 && tries < 20 {
            result = rawOperand()
            tries += 1
        }
        return result
    }

    private mutating func rawOperand() -> Fraction {
        let s = settings
        let d = Int.random(in: s.denominatorMin...s.denominatorMax, using: &rng)
        var upper = s.numeratorMax
        if s.properFractionsOnly { upper = min(upper, d - 1) }
        let n = upper >= s.numeratorMin
            ? Int.random(in: s.numeratorMin...upper, using: &rng)
            : Int.random(in: s.numeratorMin...s.numeratorMax, using: &rng)
        return Fraction(n, d)
    }

    /// A proper fraction (0 < f < 1) for conversion drills, drawn from the denominator range.
    private mutating func conversionFraction(allowRepeating: Bool) -> Fraction {
        let range = max(2, settings.denominatorMin)...max(2, settings.denominatorMax)
        var denominators = Array(range)
        if !allowRepeating {
            denominators = denominators.filter(Fraction.isTerminatingDenominator)
            if denominators.isEmpty { denominators = ProblemGenerator.fallbackTerminatingDenominators }
        }
        let d = denominators.randomElement(using: &rng)!
        let n = Int.random(in: 1...(d - 1), using: &rng)
        return Fraction(n, d)
    }
}
