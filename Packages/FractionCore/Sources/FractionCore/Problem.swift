import Foundation

public enum ProblemKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case addition
    case subtraction
    case multiplication
    case division
    case fractionToDecimal
    case decimalToFraction

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .addition: "Addition"
        case .subtraction: "Subtraction"
        case .multiplication: "Multiplication"
        case .division: "Division"
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
        case .fractionToDecimal: "→dec"
        case .decimalToFraction: "→frac"
        }
    }

    public var isArithmetic: Bool {
        switch self {
        case .addition, .subtraction, .multiplication, .division: true
        case .fractionToDecimal, .decimalToFraction: false
        }
    }
}

public struct Problem: Equatable, Sendable {
    public enum AnswerFormat: Equatable, Sendable { case fraction, decimal }

    public let kind: ProblemKind
    public let left: Fraction
    /// Second operand for arithmetic problems; nil for conversions.
    public let right: Fraction?
    /// The value the player must enter. For rounded decimal answers this is already rounded.
    public let answer: Fraction
    /// Set when a repeating decimal must be entered rounded to this many places.
    public let roundedPlaces: Int?

    public init(kind: ProblemKind, left: Fraction, right: Fraction? = nil, answer: Fraction, roundedPlaces: Int? = nil) {
        self.kind = kind
        self.left = left
        self.right = right
        self.answer = answer
        self.roundedPlaces = roundedPlaces
    }

    public var answerFormat: AnswerFormat {
        kind == .fractionToDecimal ? .decimal : .fraction
    }

    /// Operator shown between the operands, or nil for conversions.
    public var operatorSymbol: String? {
        switch kind {
        case .addition: "+"
        case .subtraction: "−"
        case .multiplication: "×"
        case .division: "÷"
        case .fractionToDecimal, .decimalToFraction: nil
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
        default:
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
            if requireLowestTerms && !parsed.typedInLowestTerms { return false }
            return true
        case .decimal:
            return parsed.form != .fraction
        }
    }
}
