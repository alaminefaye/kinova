package com.kinova.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    // Au premier plan, FCM n'affiche rien : Flutter montre une bannière et joue le son ici.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kinova/notification_sound")
            .setMethodCallHandler { call, result ->
                if (call.method == "play") {
                    RingtoneManager.getRingtone(applicationContext, soundUri())?.play()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun soundUri(): Uri = Uri.parse(
        "${ContentResolver.SCHEME_ANDROID_RESOURCE}://$packageName/${R.raw.kinova_notification}",
    )

    // L'id doit correspondre au manifest et à FirebasePushService (Laravel).
    // Le son d'un canal Android est figé à sa création : changer de son = nouvel id.
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        manager.deleteNotificationChannel("kinova_default")

        val sound = soundUri()
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val channel = NotificationChannel(
            "kinova_alerts",
            "Commandes et actualités",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Suivi des commandes, nouvelles commandes et offres KINOVA"
            setSound(sound, attributes)
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }
}
