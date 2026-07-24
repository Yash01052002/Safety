package app.suraksha

import android.content.Intent
import android.net.Uri
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

/**
 * Phone-side receiver for the Wear OS companion. When the watch sends a `/sos`
 * message, this launches the `suraksha://sos` deep link — which
 * QuickTriggerService turns into an SOS — even if the app was in the background
 * or closed.
 *
 * Wiring (phone `android/app`):
 *  1. Add `implementation 'com.google.android.gms:play-services-wearable:18.2.0'`
 *     to android/app/build.gradle.
 *  2. Declare this <service> with the MESSAGE_RECEIVED intent-filter in
 *     AndroidManifest.xml (see the committed manifest).
 */
class SosWearListenerService : WearableListenerService() {

    override fun onMessageReceived(event: MessageEvent) {
        if (event.path == PATH_SOS) {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(SOS_URI)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    companion object {
        private const val PATH_SOS = "/sos"
        private const val SOS_URI = "suraksha://sos"
    }
}
