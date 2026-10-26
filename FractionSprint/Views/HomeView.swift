import SwiftUI
import FractionCore

/// Settings and the start button on one screen, like zetamac's front page.
struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var playing = false
    @State private var showingHistory = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            Form {
                bestSection
                operationsSection
                numbersSection
                answersSection
                durationSection
            }
            .navigationTitle("Fraction Sprint")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingAbout = true } label: { Image(systemName: "info.circle") }
                        .accessibilityLabel("About")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingHistory = true } label: { Image(systemName: "chart.xyaxis.line") }
                        .accessibilityLabel("History")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    playing = true
                } label: {
                    Text("Start")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .disabled(model.settings.enabledKinds.isEmpty)
                .padding()
                .background(.bar)
            }
            .fullScreenCover(isPresented: $playing) {
                GameView(settings: model.settings)
                    .environmentObject(model)
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView().environmentObject(model)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }

    // MARK: Sections

    @ViewBuilder
    private var bestSection: some View {
        let stats = model.stats(for: model.settings)
        if stats.runs > 0 {
            Section {
                HStack {
                    statTile("Best", stats.best.map(String.init) ?? "–")
                    Divider()
                    statTile("Last 10 avg", stats.recentAverage.map { String(format: "%.1f", $0) } ?? "–")
                    Divider()
                    statTile("Runs", "\(stats.runs)")
                }
            } footer: {
                Text("For these settings")
            }
        }
    }

    private var operationsSection: some View {
        Section {
            ForEach(ProblemKind.allCases) { kind in
                Toggle(kind.title, isOn: kindBinding(kind))
            }
        } header: {
            Text("Problems")
        } footer: {
            if model.settings.enabledKinds.isEmpty {
                Text("Turn on at least one problem type.").foregroundStyle(.red)
            }
        }
    }

    private var numbersSection: some View {
        Section {
            Stepper(value: $model.settings.numeratorMin, in: GameSettings.rangeLimit.lowerBound...model.settings.numeratorMax) {
                LabeledContent("Numerator from", value: "\(model.settings.numeratorMin)")
            }
            Stepper(value: $model.settings.numeratorMax, in: model.settings.numeratorMin...GameSettings.rangeLimit.upperBound) {
                LabeledContent("Numerator to", value: "\(model.settings.numeratorMax)")
            }
            Stepper(value: $model.settings.denominatorMin, in: GameSettings.rangeLimit.lowerBound...model.settings.denominatorMax) {
                LabeledContent("Denominator from", value: "\(model.settings.denominatorMin)")
            }
            Stepper(value: $model.settings.denominatorMax, in: model.settings.denominatorMin...GameSettings.rangeLimit.upperBound) {
                LabeledContent("Denominator to", value: "\(model.settings.denominatorMax)")
            }
            Toggle("Proper fractions only", isOn: $model.settings.properFractionsOnly)
        } header: {
            Text("Numbers")
        } footer: {
            Text("Operands are drawn from these ranges and shown in lowest terms. Conversions use the denominator range.")
        }
        .monospacedDigit()
    }

    private var answersSection: some View {
        Section("Answers") {
            Toggle("Require lowest terms", isOn: $model.settings.requireLowestTerms)
            if model.settings.enabledKinds.contains(.fractionToDecimal) {
                Toggle("Repeating decimals (3 d.p.)", isOn: $model.settings.includeRepeatingDecimals)
            }
        }
    }

    private var durationSection: some View {
        Section("Duration") {
            Picker("Duration", selection: $model.settings.durationSeconds) {
                ForEach(GameSettings.durationOptions, id: \.self) { seconds in
                    Text(seconds < 60 ? "\(seconds)s" : "\(seconds / 60) min").tag(seconds)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    // MARK: Helpers

    private func kindBinding(_ kind: ProblemKind) -> Binding<Bool> {
        Binding {
            model.settings.enabledKinds.contains(kind)
        } set: { on in
            if on {
                model.settings.enabledKinds.insert(kind)
            } else {
                model.settings.enabledKinds.remove(kind)
            }
        }
    }

    private func statTile(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
