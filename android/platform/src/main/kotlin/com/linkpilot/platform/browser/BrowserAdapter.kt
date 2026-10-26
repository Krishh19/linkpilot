package com.linkpilot.platform.browser

import android.content.Intent

enum class CapabilityStatus {
    VERIFIED,
    BEST_EFFORT,
    UNSUPPORTED
}

data class BrowserCapability(
    val packageName: String,
    val displayName: String,
    val privateModeStatus: CapabilityStatus,
    val applyPrivateMode: (Intent) -> Unit,
    val notes: String
)

object BrowserAdapterTable {
    val entries: Map<String, BrowserCapability> = mapOf(
        // Firefox Family
        "org.mozilla.firefox" to BrowserCapability(
            packageName = "org.mozilla.firefox",
            displayName = "Firefox",
            privateModeStatus = CapabilityStatus.BEST_EFFORT,
            applyPrivateMode = { intent ->
                intent.putExtra("private_browsing_mode", true)
            },
            notes = "Uses 'private_browsing_mode' boolean extra."
        ),
        "org.mozilla.firefox_beta" to BrowserCapability(
            packageName = "org.mozilla.firefox_beta",
            displayName = "Firefox Beta",
            privateModeStatus = CapabilityStatus.BEST_EFFORT,
            applyPrivateMode = { intent ->
                intent.putExtra("private_browsing_mode", true)
            },
            notes = "Uses 'private_browsing_mode' boolean extra."
        ),
        "org.mozilla.fenix" to BrowserCapability(
            packageName = "org.mozilla.fenix",
            displayName = "Firefox Nightly",
            privateModeStatus = CapabilityStatus.BEST_EFFORT,
            applyPrivateMode = { intent ->
                intent.putExtra("private_browsing_mode", true)
            },
            notes = "Uses 'private_browsing_mode' boolean extra."
        ),
        "org.mozilla.focus" to BrowserCapability(
            packageName = "org.mozilla.focus",
            displayName = "Firefox Focus",
            privateModeStatus = CapabilityStatus.VERIFIED,
            applyPrivateMode = { /* Focus is always private by design */ },
            notes = "Firefox Focus is ephemeral and private by architecture."
        ),

        // Chromium Family
        "com.android.chrome" to BrowserCapability(
            packageName = "com.android.chrome",
            displayName = "Google Chrome",
            privateModeStatus = CapabilityStatus.BEST_EFFORT,
            applyPrivateMode = { intent ->
                intent.putExtra("com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB", true)
            },
            notes = "Chrome restricts incognito intent to first-party apps on modern Android."
        ),
        "com.brave.browser" to BrowserCapability(
            packageName = "com.brave.browser",
            displayName = "Brave",
            privateModeStatus = CapabilityStatus.BEST_EFFORT,
            applyPrivateMode = { intent ->
                intent.putExtra("com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB", true)
            },
            notes = "Chromium fork; supports incognito tab extra."
        ),
        "com.microsoft.emmx" to BrowserCapability(
            packageName = "com.microsoft.emmx",
            displayName = "Microsoft Edge",
            privateModeStatus = CapabilityStatus.BEST_EFFORT,
            applyPrivateMode = { intent ->
                intent.putExtra("com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB", true)
            },
            notes = "Chromium fork; supports incognito tab extra."
        ),
        "com.vivaldi.browser" to BrowserCapability(
            packageName = "com.vivaldi.browser",
            displayName = "Vivaldi",
            privateModeStatus = CapabilityStatus.BEST_EFFORT,
            applyPrivateMode = { intent ->
                intent.putExtra("com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB", true)
            },
            notes = "Chromium fork; supports incognito tab extra."
        ),
        "com.opera.browser" to BrowserCapability(
            packageName = "com.opera.browser",
            displayName = "Opera",
            privateModeStatus = CapabilityStatus.UNSUPPORTED,
            applyPrivateMode = { },
            notes = "No public intent extra supported for private tabs."
        ),
        "com.opera.mini.native" to BrowserCapability(
            packageName = "com.opera.mini.native",
            displayName = "Opera Mini",
            privateModeStatus = CapabilityStatus.UNSUPPORTED,
            applyPrivateMode = { },
            notes = "No public intent extra supported for private tabs."
        ),
        "com.duckduckgo.mobile.android" to BrowserCapability(
            packageName = "com.duckduckgo.mobile.android",
            displayName = "DuckDuckGo",
            privateModeStatus = CapabilityStatus.VERIFIED,
            applyPrivateMode = { },
            notes = "DuckDuckGo is inherently private; all sessions are ephemeral."
        ),
        "com.sec.android.app.sbrowser" to BrowserCapability(
            packageName = "com.sec.android.app.sbrowser",
            displayName = "Samsung Internet",
            privateModeStatus = CapabilityStatus.UNSUPPORTED,
            applyPrivateMode = { },
            notes = "Secret Mode is restricted to Samsung internal framework."
        )
    )

    fun getCapability(packageName: String): BrowserCapability {
        return entries[packageName] ?: BrowserCapability(
            packageName = packageName,
            displayName = packageName,
            privateModeStatus = CapabilityStatus.UNSUPPORTED,
            applyPrivateMode = {},
            notes = "Unregistered browser; no known private mode extras."
        )
    }
}
