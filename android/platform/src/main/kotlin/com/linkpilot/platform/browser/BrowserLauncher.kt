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
                val capability = BrowserAdapterTable.getCapability(targetPackage)
                capability.applyPrivateMode(intent)
            }

            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
