package app.suraksha

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

/**
 * Home-screen widget with a single big SOS button. Tapping it opens the app via
 * the `suraksha://sos` deep link, which QuickTriggerService turns into an SOS —
 * so help is one tap away without unlocking to the app first.
 *
 * Wiring (after `flutter create .` generates the android/ shell):
 *  1. Keep this file under android/app/src/main/kotlin/app/suraksha/ and make
 *     sure the module namespace/applicationId is `app.suraksha`
 *     (android/app/build.gradle) — or change the package above to match.
 *  2. The <receiver> + <meta-data> are declared in AndroidManifest.xml.
 */
class SosWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.sos_widget)

            val intent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("suraksha://sos")
            ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val pending = PendingIntent.getActivity(context, 0, intent, flags)

            views.setOnClickPendingIntent(R.id.sos_widget_button, pending)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
