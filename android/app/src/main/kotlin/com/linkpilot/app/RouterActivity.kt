package com.linkpilot.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import com.linkpilot.core.cleaner.ParsedUrl
import com.linkpilot.core.engine.LinkRouterEngine
import com.linkpilot.core.model.Action
import com.linkpilot.core.model.Decision
import com.linkpilot.core.model.Match
import com.linkpilot.core.model.Mode
import com.linkpilot.core.model.Rule
import com.linkpilot.platform.browser.BrowserDiscovery
import com.linkpilot.platform.browser.BrowserLauncher
import com.linkpilot.platform.picker.PickerBottomSheet
import com.linkpilot.platform.picker.RuleCreationChoice
import com.linkpilot.platform.storage.StorageManager
import java.util.UUID

class RouterActivity : ComponentActivity() {

    private lateinit var storageManager: StorageManager
    private lateinit var browserDiscovery: BrowserDiscovery
    private lateinit var browserLauncher: BrowserLauncher
    private lateinit var engine: LinkRouterEngine

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        storageManager = StorageManager(applicationContext)
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

        when (val decision = routingResult.decision) {
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
                        finishQuietly()
                        return
                    }
                }

                // If launch failed, fall back to picker with error notice
                showPicker(
                    cleanedUrl = routingResult.cleanedUrl,
                    removedParams = routingResult.removedParams,
                    sourcePackage = sourcePackage,
                    launchError = "Could not open with the chosen app. Please pick a browser."
                )
            }

            is Decision.ShowPicker -> {
                showPicker(
                    cleanedUrl = routingResult.cleanedUrl,
                    removedParams = routingResult.removedParams,
                    sourcePackage = sourcePackage,
                    launchError = null
                )
            }
        }
    }

    private fun showPicker(
        cleanedUrl: String,
        removedParams: List<String>,
        sourcePackage: String?,
        launchError: String?
    ) {
        val usageCounters = storageManager.getUsageCounters()
        val browsers = browserDiscovery.getInstalledBrowsers(usageCounters)

        if (browsers.isEmpty()) {
            // No browsers found, cannot route
            finish()
            return
        }

        setContent {
            MaterialTheme {
                PickerBottomSheet(
                    cleanedUrl = cleanedUrl,
                    removedParams = removedParams,
                    sourcePackage = sourcePackage,
                    browsers = browsers,
                    launchErrorMessage = launchError,
                    onSelect = { selectedPkg, mode, choice ->
                        handleUserChoice(
                            cleanedUrl = cleanedUrl,
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
        cleanedUrl: String,
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
                val parsed = ParsedUrl.parse(cleanedUrl)
                if (parsed != null) {
                    val domainPattern = "*.${parsed.asciiHost}"
                    val newRule = Rule(
                        id = UUID.randomUUID().toString(),
                        name = "Always for ${parsed.rawHost}",
                        priority = 10,
                        match = Match(domains = listOf(domainPattern)),
                        action = Action.OpenInBrowser(selectedPkg, mode),
                        enabled = true
                    )
                    val updated = storageManager.getRules() + newRule
                    storageManager.saveRules(updated)
                }
            }

            RuleCreationChoice.ALWAYS_THIS_APP -> {
                if (!sourcePackage.isNullOrBlank()) {
                    val newRule = Rule(
                        id = UUID.randomUUID().toString(),
                        name = "Always from $sourcePackage",
                        priority = 5,
                        match = Match(sourcePackages = listOf(sourcePackage)),
                        action = Action.OpenInBrowser(selectedPkg, mode),
                        enabled = true
                    )
                    val updated = storageManager.getRules() + newRule
                    storageManager.saveRules(updated)
                }
            }
        }

        browserLauncher.launch(cleanedUrl, selectedPkg, mode)
        storageManager.incrementUsage(selectedPkg)
        finishQuietly()
    }

    private fun extractUrlFromIntent(intent: Intent): String? {
        val action = intent.action
        if (action == Intent.ACTION_VIEW) {
            return intent.dataString
        } else if (action == Intent.ACTION_SEND) {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
            // Extract first http or https URL from shared text
            val regex = Regex("https?://[^\\s]+")
            return regex.find(text)?.value
        }
        return null
    }

    private fun extractSourcePackage(): String? {
        val referrer: Uri? = referrer
        if (referrer != null && referrer.scheme == "android-app") {
            return referrer.authority
        }
        return null
    }

    private fun finishQuietly() {
        finish()
        overridePendingTransition(0, 0)
    }
}
