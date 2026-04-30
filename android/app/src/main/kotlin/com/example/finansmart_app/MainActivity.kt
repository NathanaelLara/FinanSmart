package com.example.finansmart_app

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NativeNotificationEvents.EVENT_CHANNEL
        ).setStreamHandler(NativeNotificationEvents)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NativeNotificationEvents.METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationListenerSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        val expectedComponent = ComponentName(this, BankNotificationListenerService::class.java)
            .flattenToString()

        return TextUtils.split(enabledListeners, ":").any { listener ->
            listener.equals(expectedComponent, ignoreCase = true)
        }
    }
}
