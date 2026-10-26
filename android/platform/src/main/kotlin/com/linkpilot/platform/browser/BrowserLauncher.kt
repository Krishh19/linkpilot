package com.linkpilot.platform.browser

import android.content.Context
import android.content.Intent
import android.net.Uri
import com.linkpilot.core.model.Mode

class BrowserLauncher(private val context: Context) {

    fun launch(url: String, targetPackage: String, mode: Mode = Mode.NORMAL): Boolean {
        // Enforce anti-loop rule: never target our own package
        if (targetPackage == context.packageName) {
            return false
        }

        return try {
            val uri = Uri.parse(url)
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                setPackage(targetPackage)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            if (mode == Mode.PRIVATE) {
                applyPrivateModeExtras(intent, targetPackage)
            }

            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun applyPrivateModeExtras(intent: Intent, targetPackage: String) {
        when {
            targetPackage.contains("firefox", ignoreCase = true) -> {
                intent.putExtra("private_browsing_mode", true)
            }
            targetPackage.contains("brave", ignoreCase = true) ||
            targetPackage.contains("chrome", ignoreCase = true) ||
            targetPackage.contains("emmx", ignoreCase = true) -> {
                intent.putExtra("com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB", true)
            }
        }
    }
}
