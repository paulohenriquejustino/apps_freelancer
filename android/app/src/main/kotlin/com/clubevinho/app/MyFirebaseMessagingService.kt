package com.clubevinho.app

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d("FCM", "Mensagem recebida: ${remoteMessage.data}")

        remoteMessage.notification?.let {
            Log.d("FCM", "Título: ${it.title}")
            Log.d("FCM", "Corpo: ${it.body}")
        }
    }

    override fun onNewToken(token: String) {
        Log.d("FCM", "Novo token: $token")
        // Envie o token ao seu backend se necessário
    }
}
