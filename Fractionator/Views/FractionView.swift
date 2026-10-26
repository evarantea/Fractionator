import SwiftUI
import FractionCore

/// A fraction drawn the way it is written on paper: numerator over a bar over denominator.
struct StackedFraction: View {
    let numerator: String
    let denominator: String
    var size: CGFloat = 44
    var placeholderDenominator = false

    var body: some View {
        VStack(spacing: size * 0.08) {
            Text(numerator)
            Rectangle()
                .frame(height: max(2, size * 0.06))
                .frame(minWidth: size * 0.7)
            Text(denominator)
                .foregroundStyle(placeholderDenominator ? HierarchicalShapeStyle.tertiary : HierarchicalShapeStyle.primary)
        }
        .font(.system(size: size, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .fixedSize()
    }
}

struct FractionView: View {
    let fraction: Fraction
    var size: CGFloat = 44

    var body: some View {
        if fraction.isWhole {
            Text("\(fraction.numerator)")
                .font(.system(size: size, weight: .semibold, design: .rounded))
                .monospacedDigit()
        } else {
            StackedFraction(numerator: "\(fraction.numerator)", denominator: "\(fraction.denominator)", size: size)
        }
    }
}

/// The question part of a problem, e.g. "3/4 + 1/6 =".
struct ProblemView: View {
    let problem: Problem
    var size: CGFloat = 44

    var body: some View {
        HStack(spacing: size * 0.35) {
            switch problem.kind {
            case .decimalToFraction:
                Text(problem.decimalPrompt ?? "")
                    .font(.system(size: size, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            case .simplify:
                if let w = problem.written {
                    StackedFraction(numerator: "\(w.numerator)", denominator: "\(w.denominator)", size: size)
                }
            case .power:
                PowerView(base: problem.left, exponent: problem.exponent ?? 1, size: size)
            case .oneMinusPower:
                Text("1")
                    .font(.system(size: size, weight: .semibold, design: .rounded))
                symbolText("−")
                PowerView(base: problem.left, exponent: problem.exponent ?? 1, size: size)
            default:
                FractionView(fraction: problem.left, size: size)
                if let symbol = problem.operatorSymbol, let right = problem.right {
                    symbolText(symbol)
                    FractionView(fraction: right, size: size)
                }
            }
            symbolText("=")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(problem.promptText)
    }

    private func symbolText(_ s: String) -> some View {
        Text(s)
            .font(.system(size: size * 0.8, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

/// A bracketed fraction with a superscript exponent, e.g. (2/3)³.
struct PowerView: View {
    let base: Fraction
    let exponent: Int
    var size: CGFloat = 44

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack(spacing: size * 0.05) {
                bracket("(")
                FractionView(fraction: base, size: size)
                bracket(")")
            }
            Text("\(exponent)")
                .font(.system(size: size * 0.6, weight: .semibold, design: .rounded))
                .padding(.leading, size * 0.04)
        }
    }

    private func bracket(_ s: String) -> some View {
        Text(s)
            .font(.system(size: base.isWhole ? size : size * 2.2, weight: .light, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

/// What the player has typed so far, drawn stacked once they press "/".
struct AnswerInputView: View {
    let input: String
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let slash = input.firstIndex(of: "/") {
                let negative = input.hasPrefix("-")
                let num = String(input[..<slash].drop(while: { $0 == "-" }))
                let den = String(input[input.index(after: slash)...])
                HStack(spacing: size * 0.15) {
                    if negative {
                        Text("−").font(.system(size: size, weight: .semibold, design: .rounded))
                    }
                    StackedFraction(numerator: num,
                                    denominator: den.isEmpty ? "?" : den,
                                    size: size,
                                    placeholderDenominator: den.isEmpty)
                }
            } else {
                Text(input.isEmpty ? "?" : input.replacingOccurrences(of: "-", with: "−"))
                    .font(.system(size: size, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(input.isEmpty ? HierarchicalShapeStyle.tertiary : HierarchicalShapeStyle.primary)
            }
        }
        .frame(minWidth: size * 1.4)
        .accessibilityLabel(input.isEmpty ? "No answer yet" : "Your answer \(input)")
    }
}
