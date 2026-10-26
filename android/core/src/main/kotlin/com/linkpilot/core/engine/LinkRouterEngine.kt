package com.linkpilot.core.engine

import com.linkpilot.core.cleaner.ParsedUrl
import com.linkpilot.core.cleaner.UrlCleaner
import com.linkpilot.core.matcher.RuleMatcher
import com.linkpilot.core.model.CleanerConfig
import com.linkpilot.core.model.Decision
import com.linkpilot.core.model.PickerReason
import com.linkpilot.core.model.RoutingResult
import com.linkpilot.core.model.Rule
import com.linkpilot.core.model.Settings

class LinkRouterEngine(
    private val cleaner: UrlCleaner,
    private val matcher: RuleMatcher = RuleMatcher()
) {
    companion object {
        const val MAX_URL_LENGTH = 8192

        fun create(config: CleanerConfig): LinkRouterEngine {
            return LinkRouterEngine(UrlCleaner(config), RuleMatcher())
        }
    }

    /**
     * Executes the full routing pipeline:
     * 1. Validate URL intake (length, scheme http/https, well-formed).
     * 2. Unwrap redirects (up to 3 hops, loop-safe) and strip trackers based on cleaner level.
     * 3. Evaluate rules using numeric priority, specificity, and condition matching.
     * 4. Return RoutingResult with decision.
     */
    fun route(
        rawUrl: String,
        sourcePackage: String?,
        rules: List<Rule>,
        settings: Settings
    ): RoutingResult {
        val trimmed = rawUrl.trim()

        // 1. Intake validation
        if (trimmed.length > MAX_URL_LENGTH || trimmed.isEmpty()) {
            return RoutingResult(
                cleanedUrl = trimmed,
                originalUrl = trimmed,
                removedParams = emptyList(),
                sourcePackage = sourcePackage,
                decision = Decision.ShowPicker(PickerReason.REJECTED_INPUT)
            )
        }

        // Scheme validation
        val parsed = ParsedUrl.parse(trimmed)
        if (parsed == null || (parsed.scheme != "http" && parsed.scheme != "https")) {
            return RoutingResult(
                cleanedUrl = trimmed,
                originalUrl = trimmed,
                removedParams = emptyList(),
                sourcePackage = sourcePackage,
                decision = Decision.ShowPicker(PickerReason.REJECTED_INPUT)
            )
        }

        // 2. Unwrap redirects and clean tracking params
        val cleanResult = cleaner.clean(trimmed, settings.cleanerLevel)

        // 3. Evaluate rules on the cleaned URL
        val decision = matcher.resolveDecision(
            url = cleanResult.cleanedUrl,
            sourcePackage = sourcePackage,
            rules = rules,
            settings = settings
        )

        return RoutingResult(
            cleanedUrl = cleanResult.cleanedUrl,
            originalUrl = cleanResult.originalUrl,
            removedParams = cleanResult.removedParams,
            sourcePackage = sourcePackage,
            decision = decision
        )
    }
}
