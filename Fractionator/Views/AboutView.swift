import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "?"
        let b = info?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("How to play") {
                    Text("Answer as many problems as you can before time runs out. The next problem appears the moment your answer is right, so there is no enter key.")
                    Text("Type a fraction with the / key, for example 3 / 4, and use − for negative answers. Whole numbers need no /. With \"Require lowest terms\" off, any equivalent fraction counts.")
                    Text("Stuck? Skip costs nothing but time, and the answers to skipped problems are shown at the end.")
                }
                Section("Privacy") {
                    Text("No account, no ads, no tracking. Your settings and history stay on this iPhone and are never sent anywhere.")
                }
                Section {
                    LabeledContent("Version", value: version)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
