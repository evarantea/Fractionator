import Foundation

/// An exact rational number, always stored in lowest terms with a positive denominator.
/// Because the form is canonical, `==` compares values.
public struct Fraction: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let numerator: Int
    public let denominator: Int

    public init(_ numerator: Int, _ denominator: Int = 1) {
        precondition(denominator != 0, "Fraction denominator must not be zero")
        let sign = denominator < 0 ? -1 : 1
        let g = Fraction.gcd(abs(numerator), abs(denominator))
        self.numerator = sign * numerator / g
        self.denominator = sign * denominator / g
    }

    public var isWhole: Bool { denominator == 1 }
    public var isZero: Bool { numerator == 0 }

    public var description: String {
        isWhole ? "\(numerator)" : "\(numerator)/\(denominator)"
    }

    public static func + (a: Fraction, b: Fraction) -> Fraction {
        Fraction(a.numerator * b.denominator + b.numerator * a.denominator, a.denominator * b.denominator)
    }

    public static func - (a: Fraction, b: Fraction) -> Fraction {
        Fraction(a.numerator * b.denominator - b.numerator * a.denominator, a.denominator * b.denominator)
    }

    public static func * (a: Fraction, b: Fraction) -> Fraction {
        Fraction(a.numerator * b.numerator, a.denominator * b.denominator)
    }

    public static func / (a: Fraction, b: Fraction) -> Fraction {
        precondition(!b.isZero, "Division by zero")
        return Fraction(a.numerator * b.denominator, a.denominator * b.numerator)
    }

    public static func < (a: Fraction, b: Fraction) -> Bool {
        a.numerator * b.denominator < b.numerator * a.denominator
    }

    // MARK: Decimals

    /// True when the decimal expansion ends (denominator has no prime factors other than 2 and 5).
    public var hasTerminatingDecimal: Bool {
        Fraction.isTerminatingDenominator(denominator)
    }

    public static func isTerminatingDenominator(_ d: Int) -> Bool {
        var d = abs(d)
        guard d > 0 else { return false }
        while d % 2 == 0 { d /= 2 }
        while d % 5 == 0 { d /= 5 }
        return d == 1
    }

    /// The value rounded half-up to `places` decimal places, as an exact fraction.
    public func rounded(toPlaces places: Int) -> Fraction {
        let scale = Fraction.pow10(places)
        let scaled = numerator * scale
        let sign = scaled < 0 ? -1 : 1
        let q = (2 * abs(scaled) + denominator) / (2 * denominator)
        return Fraction(sign * q, scale)
    }

    /// Exact decimal string for a terminating fraction, e.g. 3/8 -> "0.375". Nil if it repeats.
    public var terminatingDecimalString: String? {
        guard hasTerminatingDecimal else { return nil }
        var places = 0
        while !Fraction.isPowerOf10Multiple(denominator: denominator, places: places) { places += 1 }
        return decimalString(places: places)
    }

    /// Decimal string with exactly `places` digits after the point (value rounded half-up).
    public func decimalString(places: Int) -> String {
        let r = rounded(toPlaces: places)
        let scale = Fraction.pow10(places)
        let units = r.numerator * (scale / r.denominator)
        let sign = units < 0 ? "-" : ""
        let whole = abs(units) / scale
        guard places > 0 else { return "\(sign)\(whole)" }
        let frac = String(abs(units) % scale)
        let padded = String(repeating: "0", count: places - frac.count) + frac
        return "\(sign)\(whole).\(padded)"
    }

    // MARK: Helpers

    static func gcd(_ a: Int, _ b: Int) -> Int {
        var (a, b) = (a, b)
        while b != 0 { (a, b) = (b, a % b) }
        return a == 0 ? 1 : a
    }

    static func pow10(_ n: Int) -> Int {
        (0..<n).reduce(1) { acc, _ in acc * 10 }
    }

    private static func isPowerOf10Multiple(denominator: Int, places: Int) -> Bool {
        pow10(places) % denominator == 0
    }
}
