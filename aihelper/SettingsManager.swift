import SwiftUI

/// Defines the method used to insert transcribed text into the active application.
///
/// - `typing`: CGEvent keystroke simulation (preserves clipboard, slightly slower).
/// - `clipboard`: Clipboard paste via Cmd+V (faster, but temporarily uses clipboard).
enum InsertionMethod: String, CaseIterable {
    case typing
    case clipboard
}

/// Centralized, persistent settings for the aihelper app.
///
/// All properties use @AppStorage for automatic UserDefaults persistence.
/// Access the shared singleton from any part of the app. SwiftUI views
/// can observe changes via @ObservedObject for reactive UI updates.
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    /// The codeword that stops recording when spoken (e.g. "over").
    @AppStorage("codeword") var codeword: String = "over"

    /// Whether to simulate pressing Return after inserting transcribed text.
    @AppStorage("autoEnterEnabled") var autoEnterEnabled: Bool = false

    /// The text insertion method: typing simulation or clipboard paste.
    @AppStorage("insertionMethod") var insertionMethod: InsertionMethod = .typing

    /// Whether to show the floating recording overlay during recording.
    @AppStorage("showOverlay") var showOverlay: Bool = true

    private init() {}
}

// InsertionMethod is already RawRepresentable<String> via the String raw value,
// which makes it directly compatible with @AppStorage.
