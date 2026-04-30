package com.example.finansmart_app

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object NativeNotificationEvents : EventChannel.StreamHandler {
    const val EVENT_CHANNEL = "finansmart/bank_notifications/events"
    const val METHOD_CHANNEL = "finansmart/bank_notifications/methods"

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun send(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }
}
