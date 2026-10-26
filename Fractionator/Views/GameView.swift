import SwiftUI
import FractionCore

/// A full-screen timed run, followed by its results.
struct GameView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    private enum Phase {
        case playing
        case finished(record: RunRecord, previousBest: Int?, skipped: [Problem])
    }

    @State private var engine: GameEngine
    @State private var endDate: Date
    @State private var now = Date()
    @State private var phase = Phase.playing
    @State private var flash = false

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(settings: GameSettings) {
        _engine = State(initialValue: GameEngine(settings: settings))
        _endDate = State(initialValue: Date().addingTimeInterval(TimeInterval(settings.sanitized().durationSeconds)))
    }

    var body: some View {
        Group {
            switch phase {
            case .playing:
                playing
            case let .finished(record, previousBest, skipped):
                ResultsView(record: record, previousBest: previousBest, skipped: skipped,
                            onPlayAgain: restart, onDone: { dismiss() })
            }
        }
        .onReceive(ticker) { date in
            now = date
            if case .playing = phase, date >= endDate { finish() }
        }
    }

    private var secondsLeft: Int {
        max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
    }

    private var playing: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .padding(10)
                        .background(Circle().fill(Color(.secondarySystemBackground)))
                }
                .tint(.primary)
                .accessibilityLabel("Quit without saving")

                Spacer()

                Label("\(secondsLeft)s", systemImage: "timer")
                    .foregroundStyle(secondsLeft <= 10 ? Color.red : Color.primary)
                    .accessibilityLabel("\(secondsLeft) seconds left")

                Spacer()

                Text("Score \(engine.score)")
                    .contentTransition(.numericText())
            }
            .font(.title3.weight(.semibold))
            .monospacedDigit()
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer(minLength: 12)

            VStack(spacing: 28) {
                ProblemView(problem: engine.current)
                    .id(engine.score + engine.skips) // fresh view per problem, so it animates in
                    .transition(.push(from: .trailing))
                AnswerInputView(input: engine.input)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(flash ? Color.green.opacity(0.25) : Color(.secondarySystemBackground))
                    )
                if let places = engine.current.roundedPlaces {
                    Text("Round to \(places) decimal places")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.horizontal)

            Spacer(minLength: 12)

            KeypadView(answerFormat: engine.current.answerFormat, onKey: press, onSkip: skip)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .sensoryFeedback(.success, trigger: engine.score)
    }

    private func press(_ key: GameEngine.Key) {
        var updated = engine
        let correct = updated.press(key)
        if correct {
            withAnimation(.snappy(duration: 0.2)) { engine = updated }
            flash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeOut(duration: 0.3)) { flash = false }
            }
        } else {
            engine = updated
        }
    }

    private func skip() {
        withAnimation(.snappy(duration: 0.2)) { engine.skip() }
    }

    private func finish() {
        let record = engine.record()
        let previousBest = model.stats(for: engine.settings).best
        model.add(record)
        phase = .finished(record: record, previousBest: previousBest, skipped: engine.skipped)
    }

    private func restart() {
        let settings = model.settings
        engine = GameEngine(settings: settings)
        endDate = Date().addingTimeInterval(TimeInterval(settings.sanitized().durationSeconds))
        now = Date()
        phase = .playing
    }
}
