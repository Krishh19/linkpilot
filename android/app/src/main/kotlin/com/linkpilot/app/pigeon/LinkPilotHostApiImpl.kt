package com.linkpilot.app.pigeon

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings as AndroidSettings
import androidx.browser.customtabs.CustomTabsService
import com.linkpilot.core.engine.LinkRouterEngine
import com.linkpilot.core.model.Action
import com.linkpilot.core.model.CleanerLevel
import com.linkpilot.core.model.Decision
import com.linkpilot.core.model.Match
import com.linkpilot.core.model.Mode
import com.linkpilot.core.model.Rule
import com.linkpilot.core.model.Settings
import com.linkpilot.platform.browser.BrowserDiscovery
import com.linkpilot.platform.browser.BrowserLauncher
import com.linkpilot.platform.storage.StorageManager

class LinkPilotHostApiImpl(
    private val context: Context,
    private val storageManager: StorageManager = StorageManager.get(context),
    private val browserDiscovery: BrowserDiscovery = BrowserDiscovery(context),
    private val browserLauncher: BrowserLauncher = BrowserLauncher(context)
) : LinkPilotHostApi {

    private val engine = LinkRouterEngine.create(storageManager.getCleanerConfig())

    override fun getRules(): List<RulePigeon> {
        return storageManager.getRules().map { toPigeon(it) }
    }

    override fun saveRules(rules: List<RulePigeon>): Boolean {
        val domainRules = rules.map { fromPigeon(it) }
        storageManager.saveRules(domainRules)
        return true
    }

    override fun getSettings(): SettingsPigeon {
        val s = storageManager.getSettings()
        return SettingsPigeon(
            globalDefaultBrowser = s.globalDefaultBrowser,
            cleanerLevel = s.cleanerLevel.name,
            historyEnabled = s.historyEnabled,
            historyRetentionDays = s.historyRetentionDays.toLong(),
            schemaVersion = s.schemaVersion.toLong()
        )
    }

    override fun saveSettings(settings: SettingsPigeon): Boolean {
        val level = try {
            CleanerLevel.valueOf(settings.cleanerLevel)
        } catch (_: Exception) {
            CleanerLevel.STANDARD
        }
        val domainSettings = Settings(
            globalDefaultBrowser = settings.globalDefaultBrowser,
            cleanerLevel = level,
            historyEnabled = settings.historyEnabled,
            historyRetentionDays = settings.historyRetentionDays.toInt(),
            schemaVersion = settings.schemaVersion.toInt()
        )
        storageManager.saveSettings(domainSettings)
        return true
    }

    override fun getInstalledBrowsers(): List<BrowserPigeon> {
        val usageCounters = storageManager.getUsageCounters()
        val installed = browserDiscovery.getInstalledBrowsers(usageCounters)
        return installed.map { browser ->
            BrowserPigeon(
                packageName = browser.packageName,
                label = browser.label,
                isDefault = browser.isDefault,
                usageCount = browser.usageCount.toLong(),
                privateModeStatus = browser.privateModeStatus.name
            )
        }
    }

    override fun getBrowserSetupStatus(): BrowserSetupStatusPigeon {
        val pm = context.packageManager
        val probe = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com"))
            .addCategory(Intent.CATEGORY_BROWSABLE)
        val resolved = pm.resolveActivity(probe, PackageManager.MATCH_DEFAULT_ONLY)
        val handlerPackage = resolved?.activityInfo?.packageName
        val isLinkPilotHandler = handlerPackage == context.packageName
        val handlerLabel = when {
            handlerPackage == null -> null
            handlerPackage == "android" -> "Android chooser"
            isLinkPilotHandler -> "LinkPilot"
            else -> try {
                pm.getApplicationLabel(pm.getApplicationInfo(handlerPackage, 0)).toString()
            } catch (_: Exception) {
                handlerPackage
            }
        }

        val roleManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            context.getSystemService(Context.ROLE_SERVICE) as? RoleManager
        } else {
            null
        }

        val qualifiesForRole = pm.queryIntentActivities(
            Intent(probe).setPackage(context.packageName),
            PackageManager.MATCH_DEFAULT_ONLY
        ).isNotEmpty()
        val customTabsReady = pm.queryIntentServices(
            Intent(CustomTabsService.ACTION_CUSTOM_TABS_CONNECTION).setPackage(context.packageName),
            0
        ).isNotEmpty()

        return BrowserSetupStatusPigeon(
            roleAvailable = roleManager?.isRoleAvailable(RoleManager.ROLE_BROWSER) == true,
            roleHeld = if (roleManager != null) {
                roleManager.isRoleHeld(RoleManager.ROLE_BROWSER)
            } else {
                isLinkPilotHandler
            },
            qualifiesForBrowserRole = qualifiesForRole,
            currentHandlerPackage = handlerPackage,
            currentHandlerLabel = handlerLabel,
            isLinkPilotHandler = isLinkPilotHandler,
            customTabsReady = customTabsReady
        )
    }

    override fun requestDefaultBrowserRole(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = context.getSystemService(Context.ROLE_SERVICE) as? RoleManager
            if (roleManager != null && roleManager.isRoleHeld(RoleManager.ROLE_BROWSER)) {
                return true
            }
            if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_BROWSER)) {
                try {
                    val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_BROWSER).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(intent)
                    return true
                } catch (_: Exception) {
                    // Fall through to the default-apps settings screen.
                }
            }
        }
        return openDefaultAppsSettings()
    }

    override fun openDefaultAppsSettings(): Boolean {
        val candidates = listOf(
            Intent(AndroidSettings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS),
            Intent(AndroidSettings.ACTION_SETTINGS)
        )
        for (intent in candidates) {
            try {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (_: Exception) {
                // Try the next settings entry point.
            }
        }
        return false
    }

    override fun testRouteUrl(url: String, sourcePackage: String?): RoutingResultPigeon {
        val rules = storageManager.getRules()
        val settings = storageManager.getSettings()

        val result = engine.route(
            rawUrl = url,
            sourcePackage = sourcePackage,
            rules = rules,
            settings = settings
        )

        return when (val decision = result.decision) {
            is Decision.Launch -> {
                val action = decision.action
                val targetPkg = when (action) {
                    is Action.OpenInBrowser -> action.pkg
                    is Action.OpenInApp -> action.pkg
                    is Action.AlwaysAsk -> null
                }
                val mode = when (action) {
                    is Action.OpenInBrowser -> action.mode.name
                    else -> null
                }
                RoutingResultPigeon(
                    cleanedUrl = result.cleanedUrl,
                    originalUrl = result.originalUrl,
                    removedParams = result.removedParams,
                    sourcePackage = result.sourcePackage,
                    decisionType = "launch",
                    matchedRuleId = decision.rule?.id,
                    matchedRuleName = decision.rule?.name,
                    targetPackage = targetPkg,
                    mode = mode,
                    pickerReason = null
                )
            }
            is Decision.ShowPicker -> {
                RoutingResultPigeon(
                    cleanedUrl = result.cleanedUrl,
                    originalUrl = result.originalUrl,
                    removedParams = result.removedParams,
                    sourcePackage = result.sourcePackage,
                    decisionType = "picker",
                    matchedRuleId = null,
                    matchedRuleName = null,
                    targetPackage = null,
                    mode = null,
                    pickerReason = decision.reason.name
                )
            }
        }
    }

    override fun openInBrowser(url: String, packageName: String, mode: String): Boolean {
        val m = try {
            Mode.valueOf(mode)
        } catch (_: Exception) {
            Mode.NORMAL
        }
        val launched = browserLauncher.launch(url, packageName, m)
        if (launched) {
            storageManager.incrementUsage(packageName)
        }
        return launched
    }

    override fun getHistory(): List<HistoryItemPigeon> {
        return storageManager.getHistory().map {
            HistoryItemPigeon(
                id = it.id,
                url = it.url,
                targetPackage = it.targetPackage,
                timestampEpochMs = it.timestampEpochMs
            )
        }
    }

    override fun clearHistory(): Boolean {
        return storageManager.clearHistory()
    }

    override fun deleteHistoryItem(id: String): Boolean {
        return storageManager.deleteHistoryItem(id)
    }

    override fun exportBackupJson(): String {
        return storageManager.exportBackupJson()
    }

    override fun importBackupJson(json: String, merge: Boolean): BackupSummaryPigeon {
        val (ruleCount, success) = storageManager.importBackupJson(json, merge)
        return BackupSummaryPigeon(
            ruleCount = ruleCount.toLong(),
            schemaVersion = 1L,
            success = success,
            errorMessage = if (success) null else "Failed to parse or validate backup JSON"
        )
    }

    override fun isProUnlocked(): Boolean {
        return storageManager.isProUnlocked()
    }

    override fun setProUnlocked(unlocked: Boolean): Boolean {
        return storageManager.setProUnlocked(unlocked)
    }

    override fun isOnboardingCompleted(): Boolean {
        return storageManager.isOnboardingCompleted()
    }

    override fun setOnboardingCompleted(completed: Boolean): Boolean {
        return storageManager.setOnboardingCompleted(completed)
    }

    private fun toPigeon(rule: Rule): RulePigeon {
        val actionType = when (rule.action) {
            is Action.OpenInBrowser -> "browser"
            is Action.OpenInApp -> "app"
            is Action.AlwaysAsk -> "ask"
        }
        val targetPackage = when (val a = rule.action) {
            is Action.OpenInBrowser -> a.pkg
            is Action.OpenInApp -> a.pkg
            is Action.AlwaysAsk -> null
        }
        val mode = when (val a = rule.action) {
            is Action.OpenInBrowser -> a.mode.name
            else -> null
        }

        return RulePigeon(
            id = rule.id,
            name = rule.name,
            enabled = rule.enabled,
            priority = rule.priority.toLong(),
            domains = rule.match.domains,
            urlRegex = rule.match.urlRegex,
            sourcePackages = rule.match.sourcePackages,
            actionType = actionType,
            targetPackage = targetPackage,
            mode = mode,
            createdAtEpochMs = rule.createdAtEpochMs,
            hitCount = rule.hitCount.toLong()
        )
    }

    private fun fromPigeon(p: RulePigeon): Rule {
        val action = when (p.actionType) {
            "browser" -> {
                val mode = try {
                    p.mode?.let { Mode.valueOf(it) } ?: Mode.NORMAL
                } catch (_: Exception) {
                    Mode.NORMAL
                }
                Action.OpenInBrowser(p.targetPackage ?: "", mode)
            }
            "app" -> Action.OpenInApp(p.targetPackage ?: "")
            else -> Action.AlwaysAsk
        }

        return Rule(
            id = p.id,
            name = p.name,
            enabled = p.enabled,
            priority = p.priority.toInt(),
            match = Match(
                domains = p.domains,
                urlRegex = p.urlRegex,
                sourcePackages = p.sourcePackages
            ),
            action = action,
            createdAtEpochMs = p.createdAtEpochMs,
            hitCount = p.hitCount.toInt()
        )
    }
}
