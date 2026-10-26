import Foundation

public enum ProblemKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case addition
    case subtraction
    case multiplication
    case division
    case power
    case oneMinusPower
    case simplify
    case fractionToDecimal
    case decimalToFraction

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .addition: "Addition"
        case .subtraction: "Subtraction"
        case .multiplication: "Multiplication"
        case .division: "Division"
        case .power: "Powers  (2/3)³"
        case .oneMinusPower: "One minus  1 − (5/6)²"
        case .simplify: "Simplify  12/18"
        case .fractionToDecimal: "Fraction → decimal"
        case .decimalToFraction: "Decimal → fraction"
        }
    }

    public var shortTitle: String {
        switch self {
        case .addition: "+"
        case .subtraction: "−"
        case .multiplication: "×"
        case .division: "÷"
        case .power: "xⁿ"
        case .oneMinusPower: "1−xⁿ"
        case .simplify: "simp"
        case .fractionToDecimal: "→dec"
        case .decimalToFraction: "→frac"
        }
    }

    /// Kinds whose operands come from the numerator range.
    public var usesNumeratorRange: Bool {
        switch self {
        case .addition, .subtraction, .multiplication, .division, .power, .oneMinusPower, .simplify: true
        case .fractionToDecimal, .decimalToFraction: false
        }
    }
}

/// A fraction exactly as written, not reduced (used to show "12/18" in simplify problems).
public struct WrittenFraction: Hashable, Codable, Sendable, CustomStringConvertible {
    public let numerator: Int
    public let denominator: Int

    public init(_ numerator: Int, _ denominator: Int) {
        self.numerator = numerator
        self.denominator = denominator
    }

    public var description: String { "\(numerator)/\(denominator)" }
}

public struct Problem: Equatable, Sendable {
    public enum AnswerFormat: Equatable, Sendable { case fraction, decimal }

    public let kind: ProblemKind
    /// First operand, the base of a power, or the fraction to convert.
    public let left: Fraction
    /// Second operand for +, −, ×, ÷; nil otherwise.
    public let right: Fraction?
    /// Exponent for power problems.
    public let exponent: Int?
    /// The unreduced fraction shown in simplify problems.
    public let written: WrittenFraction?
    /// The value the player must enter. For rounded decimal answers this is already rounded.
    public let answer: Fraction
    /// Set when a repeating decimal must be entered rounded to this many places.
    public let roundedPlaces: Int?

    public init(
        kind: ProblemKind,
        left: Fraction,
        right: Fraction? = nil,
        exponent: Int? = nil,
        written: WrittenFraction? = nil,
        answer: Fraction,
        roundedPlaces: Int? = nil
    ) {
        self.kind = kind
        self.left = left
        self.right = right
        self.exponent = exponent
        self.written = written
        self.answer = answer
        self.roundedPlaces = roundedPlaces
    }

    public var answerFormat: AnswerFormat {
        kind == .fractionToDecimal ? .decimal : .fraction
    }

    /// Operator shown between two operands, or nil when there is no second operand.
    public var operatorSymbol: String? {
        switch kind {
        case .addition: "+"
        case .subtraction: "−"
        case .multiplication: "×"
        case .division: "÷"
        default: nil
        }
    }

    /// For decimal → fraction problems, the decimal shown to the player.
    public var decimalPrompt: String? {
        kind == .decimalToFraction ? left.terminatingDecimalString : nil
    }

    /// Plain-text version of the question, used for accessibility and the results review.
    public var promptText: String {
        switch kind {
        case .fractionToDecimal:
            let suffix = roundedPlaces.map { " (\($0) d.p.)" } ?? ""
            return "\(left) = ?\(suffix)"
        case .decimalToFraction:
            return "\(decimalPrompt ?? left.description) = ?"
        case .power:
            return "(\(left))\(Problem.superscript(exponent ?? 1)) = ?"
        case .oneMinusPower:
            return "1 − (\(left))\(Problem.superscript(exponent ?? 1)) = ?"
        case .simplify:
            return "\(written?.description ?? left.description) = ?"
        case .addition, .subtraction, .multiplication, .division:
            return "\(left) \(operatorSymbol ?? "?") \(right?.description ?? "?") = ?"
        }
    }

    /// The answer as the player would type it.
    public var answerText: String {
        switch answerFormat {
        case .fraction:
            return answer.description
        case .decimal:
            if let places = roundedPlaces { return answer.decimalString(places: places) }
            return answer.terminatingDecimalString ?? answer.description
        }
    }

    public func isCorrect(_ input: String, requireLowestTerms: Bool) -> Bool {
        guard let parsed = ParsedAnswer.parse(input), parsed.value == answer else { return false }
        switch answerFormat {
        case .fraction:
            if parsed.form == .decimal { return false }
            // Simplifying is the whole point of a simplify problem, so it always needs lowest terms.
            if (requireLowestTerms || kind == .simplify) && !parsed.typedInLowestTerms { return false }
            return true
        case .decimal:
            return parsed.form != .fraction
        }
    }

    public static func superscript(_ n: Int) -> String {
        let digits: [Character] = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
        let s = String(String(abs(n)).map { digits[Int(String($0))!] })
        return n < 0 ? "⁻" + s : s
    }
}
