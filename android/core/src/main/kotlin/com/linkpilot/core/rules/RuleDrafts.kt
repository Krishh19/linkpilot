package com.linkpilot.core.rules

import com.linkpilot.core.cleaner.ParsedUrl
import com.linkpilot.core.model.Action
import com.linkpilot.core.model.Match
import com.linkpilot.core.model.Mode
import com.linkpilot.core.model.Rule
import java.util.UUID

object RuleDrafts {
    private const val SITE_RULE_PRIORITY = 10
    private const val SOURCE_APP_RULE_PRIORITY = 5

    fun domainsForSite(host: String): List<String> {
        val normalized = ParsedUrl.normalizeHost(host)
        val apex = normalized.removePrefix("www.")
        return listOf("*.$apex")
    }

    fun forSite(
        host: String,
        displayHost: String = host,
        targetPackage: String,
        mode: Mode = Mode.NORMAL,
        id: String = UUID.randomUUID().toString(),
        nowEpochMs: Long = System.currentTimeMillis()
    ): Rule {
        return Rule(
            id = id,
            name = "Always for $displayHost",
            priority = SITE_RULE_PRIORITY,
            match = Match(domains = domainsForSite(host)),
            action = Action.OpenInBrowser(targetPackage, mode),
            createdAtEpochMs = nowEpochMs
        )
    }

    fun forSourceApp(
        sourcePackage: String,
        targetPackage: String,
        mode: Mode = Mode.NORMAL,
        id: String = UUID.randomUUID().toString(),
        nowEpochMs: Long = System.currentTimeMillis()
    ): Rule {
        return Rule(
            id = id,
            name = "Always from $sourcePackage",
            priority = SOURCE_APP_RULE_PRIORITY,
            match = Match(sourcePackages = listOf(sourcePackage)),
            action = Action.OpenInBrowser(targetPackage, mode),
            createdAtEpochMs = nowEpochMs
        )
    }
}
