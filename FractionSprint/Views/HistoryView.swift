import SwiftUI
import Charts
import FractionCore

struct HistoryView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    private enum Filter: String, CaseIterable, Identifiable {
        case current = "These settings"
        case all = "All runs"
        var id: String { rawValue }
    }

    @State private var filter = Filter.current
    @State private var confirmingClear = false

    private var runs: [RunRecord] {
        switch filter {
        case .current: model.history.filter { $0.settingsKey == model.settings.key }
        case .all: model.history
        }
    }

    private var stats: HistoryStats {
        model.stats(for: filter == .current ? model.settings : nil)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Show", selection: $filter) {
                        ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if runs.isEmpty {
                    ContentUnavailableView("No runs yet",
                                           systemImage: "chart.xyaxis.line",
                                           description: Text(filter == .current
                                               ? "Finish a run with these settings to see it here."
                                               : "Finish a run to see it here."))
                } else {
                    Section {
                        HStack {
                            tile("Best", stats.best.map(String.init) ?? "–")
                            tile("Average", stats.average.map { String(format: "%.1f", $0) } ?? "–")
                            tile("Runs", "\(stats.runs)")
                        }
                        if runs.count >= 2 {
                            chart.frame(height: 180)
                        }
                    } footer: {
                        if filter == .current { Text(model.settings.summary) }
                    }

                    Section("Runs") {
                        ForEach(runs) { run in
                            row(run)
                        }
                        .onDelete { offsets in
                            model.delete(ids: Set(offsets.map { runs[$0].id }))
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear", role: .destructive) { confirmingClear = true }
                        .disabled(model.history.isEmpty)
                }
            }
            .confirmationDialog("Delete all run history?", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("Delete all runs", role: .destructive) { model.clearHistory() }
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    private struct ChartPoint: Identifiable {
        let id: UUID
        let run: Int
        let score: Int
    }

    private var chart: some View {
        // Oldest on the left; one point per run, numbered so same-day runs don't overlap.
        let points = runs.reversed().enumerated().map { ChartPoint(id: $0.element.id, run: $0.offset + 1, score: $0.element.score) }
        return Chart(points) { point in
            LineMark(x: .value("Run", point.run), y: .value("Score", point.score))
                .interpolationMethod(.monotone)
            PointMark(x: .value("Run", point.run), y: .value("Score", point.score))
                .symbolSize(24)
        }
        .chartXAxisLabel("Run")
        .chartYAxisLabel("Score")
        .chartXScale(domain: 1...max(2, points.count))
    }

    private func row(_ run: RunRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(run.date, format: .dateTime.day().month().hour().minute())
                if filter == .all {
                    Text(run.settingsSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(run.score)")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
    }

    private func tile(_ title: String, _ value: String) -> some View {
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
