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

    private static let defaults = UserDefaults.standard

    /// The codeword that stops recording when spoken (e.g. "over").
    @Published var codeword: String {
        didSet { Self.defaults.set(codeword, forKey: "codeword") }
    }

    /// Whether to simulate pressing Return after inserting transcribed text.
    @Published var autoEnterEnabled: Bool {
        didSet { Self.defaults.set(autoEnterEnabled, forKey: "autoEnterEnabled") }
    }

    /// The text insertion method: typing simulation or clipboard paste.
    @Published var insertionMethod: InsertionMethod {
        didSet { Self.defaults.set(insertionMethod.rawValue, forKey: "insertionMethod") }
    }

    /// Whether to show the floating recording overlay during recording.
    @Published var showOverlay: Bool {
        didSet { Self.defaults.set(showOverlay, forKey: "showOverlay") }
    }

    private init() {
        let d = Self.defaults
        self.codeword = d.string(forKey: "codeword") ?? "over"
        self.autoEnterEnabled = d.bool(forKey: "autoEnterEnabled")
        self.insertionMethod = InsertionMethod(rawValue: d.string(forKey: "insertionMethod") ?? "") ?? .typing
        self.showOverlay = d.object(forKey: "showOverlay") == nil ? true : d.bool(forKey: "showOverlay")
    }
}

// InsertionMethod is already RawRepresentable<String> via the String raw value,
// which makes it directly compatible with @AppStorage.
