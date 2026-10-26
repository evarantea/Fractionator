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

/// What the player has typed so far, drawn stacked once they press "/".
struct AnswerInputView: View {
    let input: String
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let slash = input.firstIndex(of: "/") {
                let num = String(input[..<slash])
                let den = String(input[input.index(after: slash)...])
                StackedFraction(numerator: num,
                                denominator: den.isEmpty ? "?" : den,
                                size: size,
                                placeholderDenominator: den.isEmpty)
            } else {
                Text(input.isEmpty ? "?" : input)
                    .font(.system(size: size, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(input.isEmpty ? HierarchicalShapeStyle.tertiary : HierarchicalShapeStyle.primary)
            }
        }
        .frame(minWidth: size * 1.4)
        .accessibilityLabel(input.isEmpty ? "No answer yet" : "Your answer \(input)")
    }
}
