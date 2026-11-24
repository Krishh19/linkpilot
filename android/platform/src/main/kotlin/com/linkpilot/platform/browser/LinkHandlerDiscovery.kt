package com.linkpilot.platform.browser

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.drawable.Drawable
import android.net.Uri

data class LinkHandlerApp(
    val packageName: String,
    val label: String,
    val icon: Drawable?,
    val isDefault: Boolean = false
)

class LinkHandlerDiscovery(private val context: Context) {

    fun getInstalledHandlers(
        url: String,
        excludedPackages: Set<String>
    ): List<LinkHandlerApp> {
        val pm = context.packageManager
        val viewIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            .addCategory(Intent.CATEGORY_BROWSABLE)

        val resolveInfos: List<ResolveInfo> = try {
            pm.queryIntentActivities(viewIntent, PackageManager.MATCH_ALL)
        } catch (_: Exception) {
            emptyList()
        }

        val defaultPackageName = try {
            pm.resolveActivity(viewIntent, PackageManager.MATCH_DEFAULT_ONLY)
                ?.activityInfo?.packageName
        } catch (_: Exception) {
            null
        }

        val candidates = resolveInfos.mapNotNull { info ->
            val activityInfo = info.activityInfo ?: return@mapNotNull null
            if (!activityInfo.exported) return@mapNotNull null
            val pkg = activityInfo.packageName ?: return@mapNotNull null
            LinkHandlerApp(
                packageName = pkg,
                label = info.loadLabel(pm).toString(),
                icon = try {
                    info.loadIcon(pm)
                } catch (_: Exception) {
                    null
                },
                isDefault = pkg == defaultPackageName
            )
        }

        return filterLinkHandlers(
            candidates = candidates,
            excludedPackages = excludedPackages + context.packageName
        )
    }
}

internal fun filterLinkHandlers(
    candidates: List<LinkHandlerApp>,
    excludedPackages: Set<String>
): List<LinkHandlerApp> = candidates
    .filter { it.packageName !in excludedPackages }
    .distinctBy { it.packageName }
    .sortedWith(
        compareByDescending<LinkHandlerApp> { it.isDefault }
            .thenBy { it.label.lowercase() }
    )
