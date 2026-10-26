import Foundation

/// What the player typed, parsed into an exact value.
public struct ParsedAnswer: Equatable, Sendable {
    public enum Form: Equatable, Sendable { case whole, fraction, decimal }

    public let value: Fraction
    public let form: Form
    /// For `.fraction` input: whether it was typed in lowest terms (6/8 is not, 3/4 is).
    public let typedInLowestTerms: Bool

    /// Accepts "3", "3/4", "-3/4", "0.375", ".5", "2.". Returns nil for anything else,
    /// including a zero denominator or an incomplete entry such as "3/".
    public static func parse(_ raw: String) -> ParsedAnswer? {
        var s = raw.trimmingCharacters(in: .whitespaces)
        var sign = 1
        if s.hasPrefix("-") {
            sign = -1
            s.removeFirst()
        }
        guard !s.isEmpty, s.count <= 18 else { return nil }

        if s.contains("/") {
            let parts = s.split(separator: "/", omittingEmptySubsequences: false)
            guard parts.count == 2,
                  let n = digits(parts[0]), let d = digits(parts[1]), d != 0
            else { return nil }
            return ParsedAnswer(value: Fraction(sign * n, d),
                                form: .fraction,
                                typedInLowestTerms: Fraction.gcd(n, d) == 1)
        }

        if s.contains(".") {
            let parts = s.split(separator: ".", omittingEmptySubsequences: false)
            guard parts.count == 2, !(parts[0].isEmpty && parts[1].isEmpty) else { return nil }
            let whole = parts[0].isEmpty ? 0 : digits(parts[0])
            let frac = parts[1].isEmpty ? 0 : digits(parts[1])
            guard let whole, let frac else { return nil }
            let scale = Fraction.pow10(parts[1].count)
            return ParsedAnswer(value: Fraction(sign * (whole * scale + frac), scale),
                                form: .decimal,
                                typedInLowestTerms: true)
        }

        guard let n = digits(Substring(s)) else { return nil }
        return ParsedAnswer(value: Fraction(sign * n), form: .whole, typedInLowestTerms: true)
    }

    private static func digits(_ s: Substring) -> Int? {
        guard !s.isEmpty, s.count <= 9, s.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return Int(s)
    }
}
