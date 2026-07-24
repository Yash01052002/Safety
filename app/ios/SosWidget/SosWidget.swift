import WidgetKit
import SwiftUI

// Home-screen + lock-screen SOS widget. Tapping opens the app via the
// `suraksha://sos` deep link, which QuickTriggerService turns into an SOS.
//
// Setup (after `flutter create .` generates the ios/ shell, in Xcode):
//  1. File → New → Target → "Widget Extension" (uncheck "Include Live
//     Activity"); name it "SosWidget". Replace the generated file with this.
//  2. Add the widget target to the Runner scheme; set its bundle id to
//     "<your.bundle.id>.SosWidget" and a matching deployment target.
//  3. The `suraksha` URL scheme is already registered in Runner/Info.plist.

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        // Static button — a single entry that never needs refreshing.
        completion(Timeline(entries: [SimpleEntry(date: Date())], policy: .never))
    }
}

struct SimpleEntry: TimelineEntry { let date: Date }

struct SosWidgetEntryView: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.90, green: 0.22, blue: 0.21))
            Text("SOS")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.white)
        }
        .padding(6)
        .widgetURL(URL(string: "suraksha://sos"))
    }
}

@main
struct SosWidget: Widget {
    let kind: String = "SosWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SosWidgetEntryView()
        }
        .configurationDisplayName("SOS")
        .description("Tap to send an emergency SOS.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}
