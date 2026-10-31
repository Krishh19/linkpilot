package com.linkpilot.app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import com.linkpilot.core.engine.LinkRouterEngine
import com.linkpilot.core.model.Action
import com.linkpilot.core.model.Decision
import com.linkpilot.core.model.Mode
import com.linkpilot.core.model.PickerReason
import com.linkpilot.core.rules.RuleDrafts
import com.linkpilot.platform.browser.BrowserDiscovery
import com.linkpilot.platform.browser.BrowserLauncher
import com.linkpilot.platform.picker.PickerBottomSheet
import com.linkpilot.platform.picker.RuleCreationChoice
import com.linkpilot.platform.storage.StorageManager

class RouterActivity : ComponentActivity() {

    private lateinit var storageManager: StorageManager
    private lateinit var browserDiscovery: BrowserDiscovery
    private lateinit var browserLauncher: BrowserLauncher
    private lateinit var engine: LinkRouterEngine

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        storageManager = StorageManager.get(applicationContext)
        browserDiscovery = BrowserDiscovery(applicationContext)
        browserLauncher = BrowserLauncher(applicationContext)
        engine = LinkRouterEngine.create(storageManager.getCleanerConfig())

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            finish()
            return
        }

        val rawUrl = extractUrlFromIntent(intent)
        if (rawUrl.isNullOrBlank()) {
            finish()
            return
        }

        val sourcePackage = extractSourcePackage()
        val rules = storageManager.getRules()
        val settings = storageManager.getSettings()

        val routingResult = engine.route(
            rawUrl = rawUrl,
            sourcePackage = sourcePackage,
            rules = rules,
            settings = settings
        )

        val decision = routingResult.decision
        if (decision is Decision.ShowPicker && decision.reason == PickerReason.REJECTED_INPUT) {
            Toast.makeText(this, R.string.unsupported_link, Toast.LENGTH_SHORT).show()
            finishQuietly()
            return
        }

        when (decision) {
            is Decision.Launch -> {
                val action = decision.action
                val targetPkg = when (action) {
                    is Action.OpenInBrowser -> action.pkg
                    is Action.OpenInApp -> action.pkg
                    is Action.AlwaysAsk -> null
                }
                val mode = when (action) {
                    is Action.OpenInBrowser -> action.mode
                    else -> Mode.NORMAL
                }

                if (targetPkg != null) {
                    val launched = browserLauncher.launch(routingResult.cleanedUrl, targetPkg, mode)
                    if (launched) {
                        storageManager.incrementUsage(targetPkg)
                        storageManager.addHistoryItem(routingResult.cleanedUrl, targetPkg)
                        finishQuietly()
                        return
                    }
                }

                // If launch failed, fall back to picker with error notice
                showPicker(
                    cleanedUrl = routingResult.cleanedUrl,
                    originalUrl = routingResult.originalUrl,
                    removedParams = routingResult.removedParams,
                    sourcePackage = sourcePackage,
                    launchError = getString(R.string.launch_failed)
                )
            }

            is Decision.ShowPicker -> {
                showPicker(
                    cleanedUrl = routingResult.cleanedUrl,
                    originalUrl = routingResult.originalUrl,
                    removedParams = routingResult.removedParams,
                    sourcePackage = sourcePackage,
                    launchError = null
                )
            }
        }
    }

    private fun showPicker(
        cleanedUrl: String,
        originalUrl: String,
        removedParams: List<String>,
        sourcePackage: String?,
        launchError: String?
    ) {
        val usageCounters = storageManager.getUsageCounters()
        val browsers = browserDiscovery.getInstalledBrowsers(usageCounters)

        if (browsers.isEmpty()) {
            openSystemChooser(cleanedUrl)
            finishQuietly()
            return
        }

        setContent {
            MaterialTheme {
                PickerBottomSheet(
                    cleanedUrl = cleanedUrl,
                    originalUrl = originalUrl,
                    removedParams = removedParams,
                    sourcePackage = sourcePackage,
                    browsers = browsers,
                    launchErrorMessage = launchError,
                    onSelect = { selectedPkg, mode, choice, urlToOpen ->
                        handleUserChoice(
                            urlToOpen = urlToOpen,
                            sourcePackage = sourcePackage,
                            selectedPkg = selectedPkg,
                            mode = mode,
                            choice = choice
                        )
                    },
                    onDismiss = {
                        finishQuietly()
                    }
                )
            }
        }
    }

    private fun handleUserChoice(
        urlToOpen: String,
        sourcePackage: String?,
        selectedPkg: String,
        mode: Mode,
        choice: RuleCreationChoice
    ) {
        when (choice) {
            RuleCreationChoice.JUST_ONCE -> {
                // Do not create rule
            }

            RuleCreationChoice.ALWAYS_THIS_SITE -> {
                val parsed = com.linkpilot.core.cleaner.ParsedUrl.parse(urlToOpen)
                if (parsed != null) {
                    val newRule = RuleDrafts.forSite(
                        host = parsed.asciiHost,
                        displayHost = parsed.rawHost,
                        targetPackage = selectedPkg,
                        mode = mode
                    )
                    val updated = storageManager.getRules() + newRule
                    storageManager.saveRules(updated)
                }
            }

            RuleCreationChoice.ALWAYS_THIS_APP -> {
                if (!sourcePackage.isNullOrBlank()) {
                    val newRule = RuleDrafts.forSourceApp(
                        sourcePackage = sourcePackage,
                        targetPackage = selectedPkg,
                        mode = mode
                    )
                    val updated = storageManager.getRules() + newRule
                    storageManager.saveRules(updated)
                }
            }
        }

        val launched = browserLauncher.launch(urlToOpen, selectedPkg, mode)
        if (launched) {
            storageManager.incrementUsage(selectedPkg)
            storageManager.addHistoryItem(urlToOpen, selectedPkg)
        } else {
            Toast.makeText(this, R.string.launch_failed, Toast.LENGTH_LONG).show()
        }
        finishQuietly()
    }

    private fun extractUrlFromIntent(intent: Intent): String? {
        val action = intent.action
        if (action == Intent.ACTION_VIEW) {
            return intent.dataString
        } else if (action == Intent.ACTION_SEND) {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
            // Extract first http or https URL from shared text (FR-G1)
            val regex = Regex("https?://[^\\s]+")
            return regex.find(text)?.value
        } else if (action == "com.linkpilot.OPEN_COPIED_LINK") {
            // Read clipboard on explicit user tap only (FR-G2)
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? android.content.ClipboardManager
            val clip = clipboard?.primaryClip
            val text = if (clip != null && clip.itemCount > 0) {
                clip.getItemAt(0)?.coerceToText(this)?.toString()
            } else {
                null
            }
            val foundUrl = if (!text.isNullOrBlank()) {
                Regex("https?://[^\\s]+").find(text)?.value
            } else {
                null
            }
            if (foundUrl.isNullOrBlank()) {
                android.widget.Toast.makeText(this, getString(R.string.no_link_on_clipboard), android.widget.Toast.LENGTH_SHORT).show()
                return null
            }
            return foundUrl
        }
        return null
    }

    private fun extractSourcePackage(): String? {
        val referrerPackage = referrer
            ?.takeIf { it.scheme == "android-app" }
            ?.let { it.authority ?: it.host }

        val launchedFrom = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            launchedFromPackage
        } else {
            null
        }

        // getLaunchedFromPackage is most reliable, but the resolver chooser reports "android".
        // Referrer and callingPackage are fallbacks, and all of them can be null.
        return sequenceOf(launchedFrom, referrerPackage, callingPackage)
            .filterNotNull()
            .map { it.trim() }
            .firstOrNull { it.isNotEmpty() && it != packageName && it != "android" }
    }

    private fun openSystemChooser(url: String) {
        try {
            val viewIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                .addCategory(Intent.CATEGORY_BROWSABLE)
            val chooser = Intent.createChooser(viewIntent, getString(R.string.choose_app)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra(
                    Intent.EXTRA_EXCLUDE_COMPONENTS,
                    arrayOf(ComponentName(this@RouterActivity, RouterActivity::class.java))
                )
            }
            startActivity(chooser)
        } catch (_: Exception) {
            Toast.makeText(this, R.string.no_browser_found, Toast.LENGTH_LONG).show()
        }
    }

    private fun finishQuietly() {
        finish()
        overridePendingTransition(0, 0)
    }
}
