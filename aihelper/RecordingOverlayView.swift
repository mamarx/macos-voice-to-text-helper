import SwiftUI

/// A compact pill-shaped recording indicator with a pulsing red dot and "Recording" label.
///
/// Designed to be hosted inside `RecordingOverlayWindow`'s NSPanel.
/// The pulsing animation starts automatically on appear and runs continuously
/// to give clear visual feedback that recording is active.
struct RecordingOverlayView: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.2 : 0.8)
                .opacity(isPulsing ? 1.0 : 0.6)
                .animation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                    value: isPulsing
                )

            Text("Recording")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.75))
        )
        .fixedSize()
        .onAppear {
            isPulsing = true
        }
    }
}
