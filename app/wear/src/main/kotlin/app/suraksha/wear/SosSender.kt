package app.suraksha.wear

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.wear.remote.interactions.RemoteActivityHelper
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.tasks.await

/**
 * Delivers an SOS from the watch to the phone two independent ways, for
 * resilience:
 *
 *  1. **MessageClient** — sends a `/sos` message to every connected phone node.
 *     A phone-side `WearableListenerService` (SosWearListenerService, in the
 *     phone module) receives it and fires the SOS even if the phone app is not
 *     in the foreground.
 *  2. **RemoteActivityHelper** — opens the phone app at `suraksha://sos`, which
 *     QuickTriggerService turns into an SOS. Useful as a visible confirmation
 *     and a fallback if no listener is registered.
 *
 * Either path alone is enough; sending both maximizes the chance help goes out.
 */
class SosSender(private val context: Context) {

    private val messageClient = Wearable.getMessageClient(context)
    private val nodeClient = Wearable.getNodeClient(context)
    private val remoteHelper = RemoteActivityHelper(context)

    /** Returns true if at least one delivery path succeeded. */
    suspend fun sendSos(): Boolean {
        var delivered = false

        // 1) Message all connected phone nodes.
        try {
            val nodes = nodeClient.connectedNodes.await()
            for (node in nodes) {
                messageClient.sendMessage(node.id, PATH_SOS, ByteArray(0)).await()
                delivered = true
            }
        } catch (e: Exception) {
            Log.w(TAG, "MessageClient send failed", e)
        }

        // 2) Open the phone app on the deep link.
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(SOS_URI))
                .addCategory(Intent.CATEGORY_BROWSABLE)
            remoteHelper.startRemoteActivity(intent).await()
            delivered = true
        } catch (e: Exception) {
            Log.w(TAG, "RemoteActivityHelper failed", e)
        }

        return delivered
    }

    companion object {
        const val PATH_SOS = "/sos"
        const val SOS_URI = "suraksha://sos"
        private const val TAG = "SosSender"
    }
}
