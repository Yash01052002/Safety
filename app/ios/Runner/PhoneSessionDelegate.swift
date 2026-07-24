import Foundation
import UIKit
import WatchConnectivity

/// iPhone-side receiver for the Apple Watch companion. Activates a WCSession and,
/// when the watch sends an SOS (live `sendMessage` or queued `transferUserInfo`),
/// opens the `suraksha://sos` deep link — which QuickTriggerService turns into an
/// SOS — so the alert fires even if the app was backgrounded.
///
/// Wiring (in ios/Runner/AppDelegate.swift, inside
/// `application(_:didFinishLaunchingWithOptions:)`):
///
///     PhoneSessionDelegate.shared.activate()
///
/// Keep the strong reference alive via the shared singleton below.
final class PhoneSessionDelegate: NSObject, WCSessionDelegate {

    static let shared = PhoneSessionDelegate()

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func fireSosIfNeeded(_ payload: [String: Any]) {
        guard (payload["type"] as? String) == "sos" else { return }
        guard let url = URL(string: "suraksha://sos") else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // Live message while the phone app is reachable.
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        fireSosIfNeeded(message)
        replyHandler(["ok": true])
    }

    // Queued delivery (phone was asleep/unreachable when the watch sent).
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        fireSosIfNeeded(userInfo)
    }

    // MARK: required WCSessionDelegate stubs
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate to keep receiving from the watch after a switch.
        WCSession.default.activate()
    }
}
