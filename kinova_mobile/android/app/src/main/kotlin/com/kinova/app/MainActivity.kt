package com.kinova.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    // Doit correspondre à channel_id envoyé par FirebasePushService et au manifest.
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "kinova_default",
            "Commandes et actualités",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Suivi des commandes, nouvelles commandes et offres KINOVA"
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
