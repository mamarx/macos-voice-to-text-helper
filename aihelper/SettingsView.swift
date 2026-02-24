import SwiftUI

/// Settings panel for the aihelper app.
///
/// Provides a grouped macOS form with sections for recording configuration,
/// text insertion behavior, overlay visibility, and hotkey display.
/// All controls bind directly to SettingsManager's @AppStorage properties.
struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    var body: some View {
        Form {
            // MARK: - Recording

            Section("Recording") {
                TextField("Stop codeword", text: $settings.codeword, prompt: Text("over"))
                Text("Say this word during recording to stop it by voice.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Text Insertion

            Section("Text Insertion") {
                Toggle("Auto-send Enter after insertion", isOn: $settings.autoEnterEnabled)

                Picker("Insertion method", selection: $settings.insertionMethod) {
                    Text("Typing Simulation").tag(InsertionMethod.typing)
                    Text("Clipboard Paste").tag(InsertionMethod.clipboard)
                }
                .pickerStyle(.radioGroup)

                Text("Typing simulation preserves your clipboard. Clipboard paste is more reliable in some apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Overlay

            Section("Overlay") {
                Toggle("Show recording overlay", isOn: $settings.showOverlay)
            }

            // MARK: - Hotkey

            Section("Hotkey") {
                LabeledContent("Current hotkey") {
                    Text("Ctrl + Shift + Space")
                        .font(.body.monospaced())
                }
                Text("Custom hotkey configuration coming in a future update.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 350)
        .navigationTitle("aihelper Settings")
    }
}
