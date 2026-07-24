import SwiftUI

/// Entry point for the watchOS companion app.
///
/// Setup (after `flutter create .` generates the ios/ shell, in Xcode):
///  1. File → New → Target → "watchOS → App"; name it "SurakshaWatch".
///  2. Replace the generated files with the three in this folder
///     (SurakshaWatchApp / ContentView / WatchSosSender).
///  3. On the iPhone side, add PhoneSessionDelegate (in ios/Runner) and
///     activate a WCSession in AppDelegate — see docs/NATIVE_MODULES.md.
@main
struct SurakshaWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
