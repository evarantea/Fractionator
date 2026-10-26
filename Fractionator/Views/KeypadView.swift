import SwiftUI
import FractionCore

struct KeypadView: View {
    let answerFormat: Problem.AnswerFormat
    let onKey: (GameEngine.Key) -> Void
    let onSkip: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(spacing: 10) {
            grid
            HStack(spacing: 10) {
                Button(action: onSkip) {
                    Label("Skip", systemImage: "forward.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .tint(Color.gray)
                key(systemImage: "delete.left") { onKey(.delete) }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Delete")
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach([7, 8, 9, 4, 5, 6, 1, 2, 3], id: \.self) { d in
                key("\(d)") { onKey(.digit(d)) }
            }
            if answerFormat == .fraction {
                key("−", style: .accent) { onKey(.negate) }
                    .accessibilityLabel("Minus sign")
                key("0") { onKey(.digit(0)) }
                key("/", style: .accent) { onKey(.slash) }
                    .accessibilityLabel("Fraction bar")
            } else {
                Color.clear.frame(minHeight: 60)
                key("0") { onKey(.digit(0)) }
                key(".", style: .accent) { onKey(.point) }
                    .accessibilityLabel("Decimal point")
            }
        }
    }

    private enum KeyStyle { case plain, accent }

    private func key(_ title: String, style: KeyStyle = .plain, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 60)
        }
        .buttonStyle(KeyButtonStyle(accent: style == .accent))
    }

    private func key(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 60)
        }
        .buttonStyle(KeyButtonStyle(accent: false))
    }
}

private struct KeyButtonStyle: ButtonStyle {
    let accent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(accent ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent ? Color.accentColor : Color(.secondarySystemBackground))
                    .opacity(configuration.isPressed ? 0.6 : 1)
            )
            .contentShape(Rectangle())
    }
}
