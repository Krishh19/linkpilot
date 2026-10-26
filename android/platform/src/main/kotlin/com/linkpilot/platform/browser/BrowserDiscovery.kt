package com.linkpilot.platform.browser

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build

data class BrowserApp(
    val packageName: String,
    val label: String,
    val icon: Drawable?,
    val isDefault: Boolean = false,
    val usageCount: Int = 0,
    val privateModeStatus: CapabilityStatus = CapabilityStatus.UNSUPPORTED
)

class BrowserDiscovery(private val context: Context) {

    fun getInstalledBrowsers(usageCounters: Map<String, Int> = emptyMap()): List<BrowserApp> {
        val pm = context.packageManager
        val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com"))

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PackageManager.MATCH_ALL
        } else {
            PackageManager.MATCH_DEFAULT_ONLY
        }

        val resolveInfos: List<ResolveInfo> = try {
            pm.queryIntentActivities(browserIntent, flags)
        } catch (_: Exception) {
            emptyList()
        }

        val defaultResolveInfo: ResolveInfo? = try {
            pm.resolveActivity(browserIntent, PackageManager.MATCH_DEFAULT_ONLY)
        } catch (_: Exception) {
            null
        }
        val defaultPackageName = defaultResolveInfo?.activityInfo?.packageName

        val ourPackage = context.packageName
        val uniqueBrowsers = mutableMapOf<String, BrowserApp>()

        for (info in resolveInfos) {
            val pkg = info.activityInfo?.packageName ?: continue
            if (pkg == ourPackage) continue // Never include ourselves

            if (!uniqueBrowsers.containsKey(pkg)) {
                val label = info.loadLabel(pm)?.toString() ?: pkg
                val icon = try {
                    info.loadIcon(pm)
                } catch (_: Exception) {
                    null
                }
                val count = usageCounters[pkg] ?: 0
                val isDefault = (pkg == defaultPackageName)

                val capability = BrowserAdapterTable.getCapability(pkg)

                uniqueBrowsers[pkg] = BrowserApp(
                    packageName = pkg,
                    label = label,
                    icon = icon,
                    isDefault = isDefault,
                    usageCount = count,
                    privateModeStatus = capability.privateModeStatus
                )
            }
        }

        // Sort by usage count descending, then default first, then label ascending
        return uniqueBrowsers.values.sortedWith(
            compareByDescending<BrowserApp> { it.usageCount }
                .thenByDescending { it.isDefault }
                .thenBy { it.label.lowercase() }
        )
    }
}
