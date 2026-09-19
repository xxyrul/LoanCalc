package com.loancalc.loan_calc

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class UpdateCheckWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {

    companion object {
        const val TAG = "UpdateCheckWorker"
        const val NOTIFICATION_CHANNEL_ID = "loan_calc_updates"
        const val PREF_NAME = "FlutterSharedPreferences"
        const val PREF_KEY_LAST_NOTIFIED = "flutter.last_notified_update_tag"
        const val PREF_KEY_AUTO_CHECK = "flutter.auto_check_updates"
        const val PREF_KEY_NOTIF_ENABLED = "flutter.update_notifications_enabled"
        const val DEFAULT_REPO = "xxyrul/LoanCalc"
    }

    override fun doWork(): Result {
        Log.d(TAG, "Starting periodic background update check...")

        try {
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

            // Check if user disabled update notifications
            val autoCheck = prefs.getBoolean(PREF_KEY_AUTO_CHECK, true)
            val notifEnabled = prefs.getBoolean(PREF_KEY_NOTIF_ENABLED, true)
            if (!autoCheck || !notifEnabled) {
                Log.d(TAG, "Update notifications or auto-check disabled by user preference. Skipping.")
                return Result.success()
            }

            // Get current installed app version
            val currentVersion = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.packageManager.getPackageInfo(
                        context.packageName,
                        PackageManager.PackageInfoFlags.of(0)
                    ).versionName ?: "1.0.0"
                } else {
                    @Suppress("DEPRECATION")
                    context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "1.0.0"
                }
            } catch (e: Exception) {
                "1.0.0"
            }

            // Query GitHub Releases
            val url = URL("https://api.github.com/repos/$DEFAULT_REPO/releases/latest")
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                setRequestProperty("Accept", "application/vnd.github.v3+json")
                setRequestProperty("User-Agent", "LoanCalc-Background-Worker")
                connectTimeout = 15000
                readTimeout = 15000
            }

            if (connection.responseCode != HttpURLConnection.HTTP_OK) {
                Log.w(TAG, "GitHub API returned HTTP ${connection.responseCode}")
                return Result.retry()
            }

            val responseString = connection.inputStream.bufferedReader().use(BufferedReader::readText)
            val json = JSONObject(responseString)
            val latestTag = json.optString("tag_name", "")
            val cleanVersion = latestTag.replace(Regex("^[vV]"), "")

            if (latestTag.isEmpty()) {
                return Result.success()
            }

            // Compare versions
            if (isNewerVersion(currentVersion, cleanVersion)) {
                val lastNotified = prefs.getString(PREF_KEY_LAST_NOTIFIED, "")
                if (lastNotified != latestTag) {
                    Log.i(TAG, "New version detected: $latestTag (installed: $currentVersion). Sending notification.")
                    showNotification(latestTag)
                    prefs.edit().putString(PREF_KEY_LAST_NOTIFIED, latestTag).apply()
                } else {
                    Log.d(TAG, "Version $latestTag already notified previously.")
                }
            } else {
                Log.d(TAG, "App is up to date ($currentVersion >= $cleanVersion).")
            }

            return Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error checking updates in background", e)
            return Result.retry()
        }
    }

    private fun isNewerVersion(currentVer: String, latestTag: String): Boolean {
        try {
            val curParts = currentVer.replace(Regex("[^0-9.]"), "").split(".")
            val latParts = latestTag.replace(Regex("[^0-9.]"), "").split(".")

            for (i in 0 until 3) {
                val cur = curParts.getOrNull(i)?.toIntOrNull() ?: 0
                val lat = latParts.getOrNull(i)?.toIntOrNull() ?: 0
                if (lat > cur) return true
                if (lat < cur) return false
            }
            return false
        } catch (e: Exception) {
            return false
        }
    }

    private fun showNotification(tag: String) {
        createNotificationChannel()

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "updater")
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = "🎉 Kemas Kini Baharu Disediakan! ($tag)"
        val body = "Versi baharu LoanCalc sedia dimuat turun. Tekan untuk pasang sekarang."

        val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        try {
            NotificationManagerCompat.from(context).notify(1001, builder.build())
        } catch (e: SecurityException) {
            Log.e(TAG, "Notification permission missing", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "App Updates"
            val descriptionText = "Notifications for LoanCalc app updates and releases"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
            }
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
