import SwiftUI

/// The watch face: one big SOS button with status feedback.
struct ContentView: View {
    @StateObject private var sender = WatchSosSender()

    private var statusText: String {
        switch sender.phase {
        case .idle: return "Tap to alert"
        case .sending: return "Sending…"
        case .sent: return "Alert sent"
        case .queued: return "Queued — will send"
        case .failed: return "Couldn't send"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Button(action: { sender.sendSos() }) {
                ZStack {
                    Circle().fill(Color(red: 0.90, green: 0.22, blue: 0.21))
                    Text("SOS")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 96, height: 96)
            .disabled(sender.phase == .sending)

            Text(statusText)
                .font(.footnote)
                .foregroundColor(.white)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
