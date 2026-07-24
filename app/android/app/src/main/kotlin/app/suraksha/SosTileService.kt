package app.suraksha

import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

/**
 * Quick Settings tile: pull down the shade → tap "SOS" to fire an alert via the
 * `suraksha://sos` deep link. Reachable even from the lock screen shade.
 *
 * Declared as a <service> in AndroidManifest.xml with the
 * BIND_QUICK_SETTINGS_TILE permission and the qs tile intent-filter.
 */
class SosTileService : TileService() {

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onClick() {
        super.onClick()

        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("suraksha://sos"))
            .apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val flags = PendingIntent.FLAG_IMMUTABLE
            val pending = PendingIntent.getActivity(this, 0, intent, flags)
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION", "StartActivityAndCollapseDeprecated")
            startActivityAndCollapse(intent)
        }
    }
}
