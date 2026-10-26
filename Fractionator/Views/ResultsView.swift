import SwiftUI
import FractionCore

struct ResultsView: View {
    let record: RunRecord
    let previousBest: Int?
    let skipped: [Problem]
    let onPlayAgain: () -> Void
    let onDone: () -> Void

    private var isNewBest: Bool {
        record.score > 0 && record.score > (previousBest ?? 0)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Text("Score")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("\(record.score)")
                            .font(.system(size: 88, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        if isNewBest {
                            Label(previousBest == nil ? "First run with these settings" : "New best!",
                                  systemImage: "star.fill")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        } else if let previousBest {
                            Text("Best: \(previousBest)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Section {
                    LabeledContent("Settings", value: record.settingsSummary)
                    if let spa = record.secondsPerAnswer {
                        LabeledContent("Time per answer", value: String(format: "%.1fs", spa))
                    }
                    LabeledContent("Skipped", value: "\(record.skips)")
                }

                if !skipped.isEmpty {
                    Section("Skipped problems") {
                        ForEach(Array(skipped.enumerated()), id: \.offset) { _, problem in
                            HStack {
                                Text(problem.promptText.replacingOccurrences(of: " = ?", with: " ="))
                                Spacer()
                                Text(problem.answerText)
                                    .fontWeight(.semibold)
                            }
                            .monospacedDigit()
                        }
                    }
                }
            }
            .navigationTitle("Time's up")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button(action: onDone) {
                        Text("Done").frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    Button(action: onPlayAgain) {
                        Text("Play again").frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .font(.headline)
                .padding()
                .background(.bar)
            }
        }
    }
}
