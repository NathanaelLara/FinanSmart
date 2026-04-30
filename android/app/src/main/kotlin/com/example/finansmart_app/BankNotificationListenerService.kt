package com.example.finansmart_app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class BankNotificationListenerService : NotificationListenerService() {
    private val allowedBankPackages = setOf(
        "com.bancocaribe",
        "com.bancocaribe.mobile",
        "com.bancocaribe.app",
        "com.popular.app.android",
        "com.bpd.mobile",
        "com.bhdleon.mobile",
        "com.scotiabank.scotiaconnect",
        "do.com.apapmovil",
        "com.banreservas.mobile"
    )

    private val bankKeywords = listOf(
        "bancocaribe",
        "banco caribe",
        "banco popular",
        "banreservas",
        "bhd",
        "scotiabank",
        "apap",
        "consumo",
        "tcno",
        "tc no",
        "tarjeta"
    )

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        if (isKnownNonFinancialPackage(packageName)) return

        val extras = sbn.notification.extras
        val title = extras.getCharSequence("android.title")?.toString().orEmpty()
        val text = extras.getCharSequence("android.text")?.toString().orEmpty()
        val bigText = extras.getCharSequence("android.bigText")?.toString().orEmpty()
        val subText = extras.getCharSequence("android.subText")?.toString().orEmpty()
        val combinedText = listOf(title, text, bigText, subText)
            .filter { it.isNotBlank() }
            .joinToString(" ")

        if (!looksLikeBankConsumption(packageName, combinedText)) return

        NativeNotificationEvents.send(
            mapOf(
                "packageName" to packageName,
                "title" to title,
                "text" to listOf(text, bigText).firstOrNull { it.isNotBlank() }.orEmpty(),
                "subText" to subText,
                "postTime" to sbn.postTime
            )
        )
    }

    private fun looksLikeBankConsumption(packageName: String, text: String): Boolean {
        val normalizedPackage = packageName.lowercase()
        val normalizedText = text.lowercase()
        val fromAllowedBank = allowedBankPackages.any { normalizedPackage.startsWith(it) }
        val hasBankSignal = bankKeywords.any { normalizedText.contains(it) }
        val hasConsumptionSignal = normalizedText.contains("consumo") ||
            normalizedText.contains("compra") ||
            normalizedText.contains("presenta un consumo")
        val hasAmountSignal = Regex(
            """(rd${'$'}|dop|usd|${'$'})?\s*\d{1,3}(,\d{3})*(\.\d{2})"""
        )
            .containsMatchIn(normalizedText)

        return (fromAllowedBank || hasBankSignal) && hasConsumptionSignal && hasAmountSignal
    }

    private fun isKnownNonFinancialPackage(packageName: String): Boolean {
        val normalized = packageName.lowercase()
        return normalized.startsWith("com.whatsapp") ||
            normalized.startsWith("com.google.android.gm") ||
            normalized.startsWith("com.linkedin") ||
            normalized.startsWith("com.facebook") ||
            normalized.startsWith("com.instagram") ||
            normalized.startsWith("com.twitter") ||
            normalized.startsWith("com.zhiliaoapp.musically") ||
            normalized.startsWith("org.telegram")
    }
}
