package com.sabu.saku

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createCommentChannel()
        createAttentionChannel()
    }

    // The channel FCM posts teacher-comment notifications to. Its ID is also
    // the default channel in AndroidManifest.xml and the one Cloud Functions
    // sends with. Creating an existing channel is a no-op.
    private fun createCommentChannel() {
        val channel = NotificationChannel(
            "komentar_guru",
            "Komentar guru",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Pemberitahuan saat guru mengomentari jurnalmu"
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    // The channel of the teachers' morning digest about their own students
    // who need attention (Cloud Functions: teacherDigest).
    private fun createAttentionChannel() {
        val channel = NotificationChannel(
            "siswa_binaan",
            "Siswa binaan",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Pemberitahuan pagi saat siswa binaan Anda perlu perhatian"
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
