import XCTest
@testable import FractionCore

final class FractionTests: XCTestCase {
    func testNormalisation() {
        XCTAssertEqual(Fraction(6, 8), Fraction(3, 4))
        XCTAssertEqual(Fraction(3, -4).numerator, -3)
        XCTAssertEqual(Fraction(3, -4).denominator, 4)
        XCTAssertEqual(Fraction(0, 7), Fraction(0))
        XCTAssertEqual(Fraction(10, 5).description, "2")
    }

    func testArithmetic() {
        XCTAssertEqual(Fraction(1, 2) + Fraction(1, 3), Fraction(5, 6))
        XCTAssertEqual(Fraction(3, 4) - Fraction(1, 4), Fraction(1, 2))
        XCTAssertEqual(Fraction(2, 3) * Fraction(9, 4), Fraction(3, 2))
        XCTAssertEqual(Fraction(1, 2) / Fraction(1, 4), Fraction(2))
        XCTAssertLessThan(Fraction(2, 5), Fraction(1, 2))
    }

    func testDecimals() {
        XCTAssertEqual(Fraction(3, 8).terminatingDecimalString, "0.375")
        XCTAssertEqual(Fraction(1, 16).terminatingDecimalString, "0.0625")
        XCTAssertEqual(Fraction(1, 2).terminatingDecimalString, "0.5")
        XCTAssertNil(Fraction(1, 3).terminatingDecimalString)
        XCTAssertEqual(Fraction(2, 3).decimalString(places: 3), "0.667")
        XCTAssertEqual(Fraction(1, 7).decimalString(places: 3), "0.143")
        XCTAssertEqual(Fraction(2, 3).rounded(toPlaces: 3), Fraction(667, 1000))
        XCTAssertEqual(Fraction(-1, 8).decimalString(places: 2), "-0.13")
    }
}

final class ExampleProblemTests: XCTestCase {
    // The examples the app is meant to drill.
    func testExamples() {
        XCTAssertEqual(Fraction(1, 6) + Fraction(1, 9), Fraction(5, 18))
        XCTAssertEqual(Fraction(3, 4) - Fraction(5, 6), Fraction(-1, 12))
        XCTAssertEqual(Fraction(1, 2).power(5), Fraction(1, 32))
        XCTAssertEqual(Fraction(2, 3).power(3), Fraction(8, 27))
        XCTAssertEqual(Fraction(1) - Fraction(5, 6).power(2), Fraction(11, 36))
        XCTAssertEqual(Fraction(1, 8).terminatingDecimalString, "0.125")
        XCTAssertEqual(Fraction(1, 6).decimalString(places: 3), "0.167")
        XCTAssertEqual(Fraction(1, 7).decimalString(places: 3), "0.143")
        XCTAssertEqual(Fraction(1, 9).decimalString(places: 3), "0.111")
        XCTAssertEqual(Fraction(3, 7).decimalString(places: 3), "0.429")
    }

    func testPromptTexts() {
        let power = Problem(kind: .power, left: Fraction(2, 3), exponent: 3, answer: Fraction(8, 27))
        XCTAssertEqual(power.promptText, "(2/3)³ = ?")
        let oneMinus = Problem(kind: .oneMinusPower, left: Fraction(5, 6), exponent: 2, answer: Fraction(11, 36))
        XCTAssertEqual(oneMinus.promptText, "1 − (5/6)² = ?")
        let simplify = Problem(kind: .simplify, left: Fraction(2, 3), written: WrittenFraction(12, 18), answer: Fraction(2, 3))
        XCTAssertEqual(simplify.promptText, "12/18 = ?")
        XCTAssertTrue(simplify.isCorrect("2/3", requireLowestTerms: false))
        XCTAssertFalse(simplify.isCorrect("4/6", requireLowestTerms: false))
        let negative = Problem(kind: .subtraction, left: Fraction(3, 4), right: Fraction(5, 6), answer: Fraction(-1, 12))
        XCTAssertTrue(negative.isCorrect("-1/12", requireLowestTerms: true))
        XCTAssertFalse(negative.isCorrect("1/12", requireLowestTerms: true))
        XCTAssertEqual(Problem.superscript(12), "¹²")
    }
}

final class ParsedAnswerTests: XCTestCase {
    func testParsing() {
        XCTAssertEqual(ParsedAnswer.parse("3/4")?.value, Fraction(3, 4))
        XCTAssertEqual(ParsedAnswer.parse("6/8")?.typedInLowestTerms, false)
        XCTAssertEqual(ParsedAnswer.parse("3/4")?.typedInLowestTerms, true)
        XCTAssertEqual(ParsedAnswer.parse("-1/2")?.value, Fraction(-1, 2))
        XCTAssertEqual(ParsedAnswer.parse("2")?.form, .whole)
        XCTAssertEqual(ParsedAnswer.parse("0.375")?.value, Fraction(3, 8))
        XCTAssertEqual(ParsedAnswer.parse(".5")?.value, Fraction(1, 2))
        XCTAssertEqual(ParsedAnswer.parse("2.")?.value, Fraction(2))
    }

    func testRejectsIncompleteOrInvalid() {
        for s in ["", "3/", "/4", "3/0", "1/2/3", ".", "1..2", "abc", "1/2.5", "-"] {
            XCTAssertNil(ParsedAnswer.parse(s), s)
        }
    }
}

final class ProblemTests: XCTestCase {
    func testFractionAnswers() {
        let p = Problem(kind: .addition, left: Fraction(1, 4), right: Fraction(1, 2), answer: Fraction(3, 4))
        XCTAssertTrue(p.isCorrect("3/4", requireLowestTerms: true))
        XCTAssertTrue(p.isCorrect("6/8", requireLowestTerms: false))
        XCTAssertFalse(p.isCorrect("6/8", requireLowestTerms: true))
        XCTAssertFalse(p.isCorrect("0.75", requireLowestTerms: false))
        XCTAssertFalse(p.isCorrect("3/", requireLowestTerms: false))
        XCTAssertEqual(p.promptText, "1/4 + 1/2 = ?")
    }

    func testWholeAnswer() {
        let p = Problem(kind: .division, left: Fraction(1, 2), right: Fraction(1, 4), answer: Fraction(2))
        XCTAssertTrue(p.isCorrect("2", requireLowestTerms: true))
        XCTAssertFalse(p.isCorrect("4/2", requireLowestTerms: true))
        XCTAssertTrue(p.isCorrect("4/2", requireLowestTerms: false))
    }

    func testDecimalAnswers() {
        let exact = Problem(kind: .fractionToDecimal, left: Fraction(3, 8), answer: Fraction(3, 8))
        XCTAssertTrue(exact.isCorrect("0.375", requireLowestTerms: true))
        XCTAssertTrue(exact.isCorrect(".375", requireLowestTerms: true))
        XCTAssertFalse(exact.isCorrect("0.37", requireLowestTerms: true))
        XCTAssertFalse(exact.isCorrect("3/8", requireLowestTerms: true))
        XCTAssertEqual(exact.answerText, "0.375")

        let rounded = Problem(kind: .fractionToDecimal, left: Fraction(2, 3),
                              answer: Fraction(2, 3).rounded(toPlaces: 3), roundedPlaces: 3)
        XCTAssertTrue(rounded.isCorrect("0.667", requireLowestTerms: true))
        XCTAssertFalse(rounded.isCorrect("0.666", requireLowestTerms: true))
        XCTAssertEqual(rounded.answerText, "0.667")
        XCTAssertEqual(rounded.promptText, "2/3 = ? (3 d.p.)")
    }

    func testDecimalToFraction() {
        let p = Problem(kind: .decimalToFraction, left: Fraction(3, 8), answer: Fraction(3, 8))
        XCTAssertEqual(p.decimalPrompt, "0.375")
        XCTAssertTrue(p.isCorrect("3/8", requireLowestTerms: true))
        XCTAssertFalse(p.isCorrect("0.375", requireLowestTerms: true))
    }
}

final class GeneratorTests: XCTestCase {
    func testAllKindsProduceValidProblems() {
        let settings = GameSettings(enabledKinds: Set(ProblemKind.allCases), includeRepeatingDecimals: true)
        var gen = ProblemGenerator(settings: settings, rng: SplitMix64(seed: 42))
        var seen = Set<ProblemKind>()
        var sawNegative = false
        for _ in 0..<3000 {
            let p = gen.next()
            seen.insert(p.kind)
            XCTAssertTrue(p.isCorrect(p.answerText, requireLowestTerms: true), p.promptText)
            switch p.kind {
            case .addition: XCTAssertEqual(p.answer, p.left + p.right!)
            case .subtraction:
                XCTAssertEqual(p.answer, p.left - p.right!)
                XCTAssertNotEqual(p.answer, Fraction(0))
                if p.answer < Fraction(0) { sawNegative = true }
            case .multiplication: XCTAssertEqual(p.answer, p.left * p.right!)
            case .division: XCTAssertEqual(p.answer, p.left / p.right!)
            case .power:
                let n = try! XCTUnwrap(p.exponent)
                XCTAssertTrue((2...5).contains(n))
                XCTAssertEqual(p.answer, p.left.power(n))
                XCTAssertLessThanOrEqual(p.answer.denominator, 250)
            case .oneMinusPower:
                let n = try! XCTUnwrap(p.exponent)
                XCTAssertTrue((2...3).contains(n))
                XCTAssertEqual(p.answer, Fraction(1) - p.left.power(n))
            case .simplify:
                let w = try! XCTUnwrap(p.written)
                XCTAssertEqual(Fraction(w.numerator, w.denominator), p.answer)
                XCTAssertNotEqual(w.denominator, p.answer.denominator, "must need simplifying")
                XCTAssertFalse(p.isCorrect(w.description, requireLowestTerms: false))
            case .fractionToDecimal, .decimalToFraction:
                XCTAssertGreaterThan(p.left, Fraction(0))
                XCTAssertLessThan(p.left, Fraction(1))
            }
            if let right = p.right {
                for f in [p.left, right] {
                    XCTAssertGreaterThan(f, Fraction(0))
                    XCTAssertLessThan(f, Fraction(1), "proper fractions only")
                    XCTAssertFalse(f.isWhole)
                }
            }
            if p.kind == .decimalToFraction {
                XCTAssertNotNil(p.decimalPrompt)
            }
        }
        XCTAssertEqual(seen, Set(ProblemKind.allCases))
        XCTAssertTrue(sawNegative)
    }

    func testPositiveSubtractionWhenNegativesOff() {
        let settings = GameSettings(enabledKinds: [.subtraction], allowNegativeAnswers: false)
        var gen = ProblemGenerator(settings: settings, rng: SplitMix64(seed: 11))
        for _ in 0..<500 {
            XCTAssertGreaterThan(gen.next().answer, Fraction(0))
        }
    }

    func testRespectsRanges() {
        let settings = GameSettings(enabledKinds: [.addition, .subtraction, .multiplication, .division],
                                    numeratorMin: 1, numeratorMax: 5, denominatorMin: 6, denominatorMax: 9)
        var gen = ProblemGenerator(settings: settings, rng: SplitMix64(seed: 7))
        for _ in 0..<500 {
            let p = gen.next()
            // Operands are reduced, so check they could come from n in 1...5 over d in 6...9.
            for f in [p.left, p.right!] {
                let fits = (6...9).contains { d in (1...5).contains { n in Fraction(n, d) == f } }
                XCTAssertTrue(fits, "\(f)")
            }
        }
    }

    func testTerminatingOnlyWithoutRepeatingOption() {
        let settings = GameSettings(enabledKinds: [.fractionToDecimal], denominatorMin: 2, denominatorMax: 12,
                                    includeRepeatingDecimals: false)
        var gen = ProblemGenerator(settings: settings, rng: SplitMix64(seed: 1))
        for _ in 0..<300 {
            let p = gen.next()
            XCTAssertTrue(p.left.hasTerminatingDecimal)
            XCTAssertNil(p.roundedPlaces)
        }
    }

    func testRepeatingDecimalsRoundToThreePlaces() {
        let settings = GameSettings(enabledKinds: [.fractionToDecimal], denominatorMin: 7, denominatorMax: 7)
        var gen = ProblemGenerator(settings: settings, rng: SplitMix64(seed: 4))
        for _ in 0..<50 {
            let p = gen.next()
            XCTAssertEqual(p.roundedPlaces, 3)
            XCTAssertEqual(p.answerText.count, 5, p.answerText) // "0.ddd"
        }
    }

    func testNoImmediateRepeats() {
        var gen = ProblemGenerator(settings: GameSettings(), rng: SplitMix64(seed: 3))
        var last = gen.next()
        for _ in 0..<500 {
            let p = gen.next()
            XCTAssertNotEqual(p, last)
            last = p
        }
    }

    func testTinyRangeStillWorks() {
        let settings = GameSettings(numeratorMin: 1, numeratorMax: 1, denominatorMin: 2, denominatorMax: 2)
        var gen = ProblemGenerator(settings: settings, rng: SplitMix64(seed: 9))
        for _ in 0..<50 { _ = gen.next() }
    }
}

final class EngineTests: XCTestCase {
    func enter(_ s: String, into engine: inout GameEngine) -> Bool {
        var advanced = false
        for c in s {
            switch c {
            case "/": advanced = engine.press(.slash)
            case ".": advanced = engine.press(.point)
            case "-": advanced = engine.press(.negate)
            default: advanced = engine.press(.digit(Int(String(c))!))
            }
        }
        return advanced
    }

    func testCorrectAnswerAdvancesAndScores() {
        var engine = GameEngine(settings: GameSettings(), rng: SplitMix64(seed: 5))
        for i in 1...20 {
            let problem = engine.current
            XCTAssertTrue(enter(problem.answerText, into: &engine), problem.promptText)
            XCTAssertEqual(engine.score, i)
            XCTAssertEqual(engine.input, "")
        }
        XCTAssertEqual(engine.correctByKind.values.reduce(0, +), 20)
    }

    func testWrongInputDoesNotAdvance() {
        var engine = GameEngine(settings: GameSettings(enabledKinds: [.addition]), rng: SplitMix64(seed: 5))
        let before = engine.current
        engine.press(.digit(0))
        engine.press(.slash)
        engine.press(.slash) // second slash ignored
        XCTAssertEqual(engine.input, "0/")
        engine.press(.point) // decimal point not allowed for fraction answers
        XCTAssertEqual(engine.input, "0/")
        engine.press(.delete)
        XCTAssertEqual(engine.input, "0")
        XCTAssertEqual(engine.current, before)
        XCTAssertEqual(engine.score, 0)
    }

    func testSkipAndRecord() {
        var engine = GameEngine(settings: GameSettings(durationSeconds: 60), rng: SplitMix64(seed: 5))
        let skippedProblem = engine.current
        engine.skip()
        XCTAssertEqual(engine.skips, 1)
        XCTAssertEqual(engine.skipped, [skippedProblem])
        _ = enter(engine.current.answerText, into: &engine)
        let record = engine.record(date: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(record.score, 1)
        XCTAssertEqual(record.skips, 1)
        XCTAssertEqual(record.durationSeconds, 60)
        XCTAssertEqual(record.settingsKey, GameSettings(durationSeconds: 60).key)
    }

    func testNegateTogglesSign() {
        var engine = GameEngine(settings: GameSettings(enabledKinds: [.addition]), rng: SplitMix64(seed: 2))
        engine.press(.digit(1))
        engine.press(.negate)
        XCTAssertEqual(engine.input, "-1")
        engine.press(.negate)
        XCTAssertEqual(engine.input, "1")
        engine.press(.clear)
        engine.press(.negate)
        engine.press(.slash) // no digits yet, so no fraction bar
        XCTAssertEqual(engine.input, "-")
    }

    func testNegativeAnswerScores() {
        var engine = GameEngine(settings: GameSettings(enabledKinds: [.subtraction]), rng: SplitMix64(seed: 8))
        var found = false
        for _ in 0..<200 where !found {
            if engine.current.answer < Fraction(0) {
                found = true
                engine.press(.negate)
                XCTAssertTrue(enter(String(engine.current.answerText.dropFirst()), into: &engine))
            } else {
                engine.skip()
            }
        }
        XCTAssertTrue(found)
        XCTAssertEqual(engine.score, 1)
    }

    func testPointPrefixesZero() {
        var engine = GameEngine(settings: GameSettings(enabledKinds: [.fractionToDecimal]), rng: SplitMix64(seed: 2))
        engine.press(.point)
        XCTAssertEqual(engine.input, "0.")
    }
}

final class SettingsAndHistoryTests: XCTestCase {
    func testSanitize() {
        let s = GameSettings(durationSeconds: 7, enabledKinds: [], numeratorMin: 9, numeratorMax: 3,
                             denominatorMin: 0, denominatorMax: 500).sanitized()
        XCTAssertEqual(s.durationSeconds, 120)
        XCTAssertEqual(s.enabledKinds, [.addition])
        XCTAssertEqual(s.numeratorMin, 9)
        XCTAssertEqual(s.numeratorMax, 9)
        XCTAssertEqual(s.denominatorMin, 1)
        XCTAssertEqual(s.denominatorMax, 99)
    }

    func testCodableRoundTripAndMissingKeys() throws {
        let s = GameSettings(durationSeconds: 60, enabledKinds: [.division, .addition], requireLowestTerms: true)
        let data = try JSONEncoder().encode(s)
        XCTAssertEqual(try JSONDecoder().decode(GameSettings.self, from: data), s)

        let partial = #"{"durationSeconds":30,"enabledKinds":["multiplication","futureKind"]}"#
        let decoded = try JSONDecoder().decode(GameSettings.self, from: Data(partial.utf8))
        XCTAssertEqual(decoded.durationSeconds, 30)
        XCTAssertEqual(decoded.enabledKinds, [.multiplication])
        XCTAssertEqual(decoded.denominatorMax, GameSettings().denominatorMax)
    }

    func testSummaryAndKey() {
        let s = GameSettings()
        XCTAssertEqual(s.summary, "2 min · + − × ÷ xⁿ 1−xⁿ simp →dec · n 1–12 · d 2–12")
        XCTAssertNotEqual(s.key, GameSettings(durationSeconds: 60).key)
    }

    func testStats() {
        let key = GameSettings().key
        let records = (1...12).map { i in
            RunRecord(date: Date(timeIntervalSince1970: Double(i)), score: i, skips: 0,
                      durationSeconds: 120, settingsKey: key, settingsSummary: "")
        } + [RunRecord(date: Date(), score: 99, skips: 0, durationSeconds: 30, settingsKey: "other", settingsSummary: "")]
        let stats = HistoryStats(records: records, settingsKey: key)
        XCTAssertEqual(stats.runs, 12)
        XCTAssertEqual(stats.best, 12)
        XCTAssertEqual(stats.average, 6.5)
        XCTAssertEqual(stats.recentAverage, 7.5) // scores 3...12
        XCTAssertEqual(HistoryStats(records: records).best, 99)
        XCTAssertNil(HistoryStats(records: []).best)
    }
}
