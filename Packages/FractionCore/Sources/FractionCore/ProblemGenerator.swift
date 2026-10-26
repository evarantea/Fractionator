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

    /// Powers stay mental-maths sized: (5/6)³ = 125/216 and (2/3)⁵ = 32/243 are in, (6/7)³ is out.
    static let maxPowerDenominator = 250
    static let maxSimplifyDenominator = 144

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
            var a = operand(), b = operand()
            var tries = 0
            while a == b && tries < 10 {
                b = operand()
                tries += 1
            }
            // With negatives off, keep answers positive like zetamac's subtraction.
            if !settings.allowNegativeAnswers && a < b { swap(&a, &b) }
            return Problem(kind: kind, left: a, right: b, answer: a - b)

        case .multiplication:
            let a = operand(), b = operand()
            return Problem(kind: kind, left: a, right: b, answer: a * b)

        case .division:
            let a = operand(), b = operand()
            return Problem(kind: kind, left: a, right: b, answer: a / b)

        case .power:
            let (base, n) = powerBase(exponents: 2...5)
            return Problem(kind: kind, left: base, exponent: n, answer: base.power(n))

        case .oneMinusPower:
            let (base, n) = powerBase(exponents: 2...3)
            return Problem(kind: kind, left: base, exponent: n, answer: Fraction(1) - base.power(n))

        case .simplify:
            let reduced = operand()
            let maxFactor = max(2, min(12, ProblemGenerator.maxSimplifyDenominator / reduced.denominator))
            let k = Int.random(in: 2...maxFactor, using: &rng)
            let written = WrittenFraction(reduced.numerator * k, reduced.denominator * k)
            return Problem(kind: kind, left: reduced, written: written, answer: reduced)

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

    /// A base and exponent whose result keeps a denominator of at most `maxPowerDenominator`.
    private mutating func powerBase(exponents: ClosedRange<Int>) -> (Fraction, Int) {
        for _ in 0..<50 {
            let base = operand()
            let fitting = exponents.filter { n in
                base.power(n).denominator <= ProblemGenerator.maxPowerDenominator
                    && abs(base.power(n).numerator) <= ProblemGenerator.maxPowerDenominator * 4
            }
            if let n = fitting.randomElement(using: &rng) { return (base, n) }
        }
        // Ranges too large for any power to fit: fall back to small classics.
        let base = [Fraction(1, 2), Fraction(2, 3), Fraction(5, 6), Fraction(3, 4)].randomElement(using: &rng)!
        return (base, exponents.lowerBound)
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
