package com.loancalc.loan_calc

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.io.BufferedReader
import java.net.HttpURLConnection
import java.net.URL

class UpdateCheckWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {

    companion object {
        const val TAG = "UpdateCheckWorker"
        const val NOTIFICATION_CHANNEL_ID = "loan_calc_updates"
        const val DEFAULT_REPO = "xxyrul/LoanCalc"
    }

    override fun doWork(): Result {
        Log.d(TAG, "Starting background update check...")

        try {
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

            Log.d(TAG, "Installed version: $currentVersion")

            // Query GitHub Releases
            val url = URL("https://api.github.com/repos/$DEFAULT_REPO/releases/latest")
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                setRequestProperty("Accept", "application/vnd.github.v3+json")
                setRequestProperty("User-Agent", "LoanCalc-Background-Worker")
                connectTimeout = 10000
                readTimeout = 10000
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

            Log.d(TAG, "GitHub latest version: $latestTag (clean: $cleanVersion)")

            // Compare versions
            if (isNewerVersion(currentVersion, cleanVersion)) {
                Log.i(TAG, "New version detected: $latestTag > $currentVersion. Firing system notification!")
                showNotification(latestTag)
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
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        try {
            NotificationManagerCompat.from(context).notify(1001, builder.build())
            Log.i(TAG, "Notification 1001 posted successfully.")
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
                enableLights(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
