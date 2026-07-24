import Foundation
import WatchConnectivity

/// Sends an SOS from the watch to the paired iPhone over WatchConnectivity.
///
/// Uses `sendMessage` when the phone is reachable (immediate), and falls back to
/// `transferUserInfo` (queued, guaranteed delivery when the phone next connects)
/// otherwise — so an SOS is never silently dropped because the phone was asleep.
final class WatchSosSender: NSObject, ObservableObject, WCSessionDelegate {

    enum Phase { case idle, sending, sent, queued, failed }
    @Published var phase: Phase = .idle

    private let session: WCSession = .default

    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    func sendSos() {
        phase = .sending
        let payload: [String: Any] = ["type": "sos", "ts": Date().timeIntervalSince1970]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: { [weak self] _ in
                DispatchQueue.main.async { self?.phase = .sent }
            }, errorHandler: { [weak self] _ in
                // Reachable check raced with a drop — queue it instead.
                self?.queue(payload)
            })
        } else {
            queue(payload)
        }
    }

    private func queue(_ payload: [String: Any]) {
        session.transferUserInfo(payload)
        DispatchQueue.main.async { self.phase = .queued }
    }

    // MARK: WCSessionDelegate
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
}
