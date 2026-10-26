package com.linkpilot.core.cleaner

import com.linkpilot.core.model.CleanerConfig
import com.linkpilot.core.model.CleanerLevel
import com.linkpilot.core.model.RedirectWrapper
import java.net.URLDecoder
import java.nio.charset.StandardCharsets

data class CleanResult(
    val cleanedUrl: String,
    val originalUrl: String,
    val removedParams: List<String>,
    val unwrapped: Boolean
)

class UrlCleaner(
    private val config: CleanerConfig
) {
    companion object {
        private const val MAX_UNWRAP_HOPS = 3

        private val AGGRESSIVE_PREFIXES = listOf("utm_", "aff_", "fb_", "ref_")
        private val AGGRESSIVE_SUBSTRINGS = listOf("click_id", "affiliate", "tracking", "tracker")
    }

    /**
     * Cleans the given URL according to the configured cleaner rules and level.
     * 1. Unwraps redirect wrappers (up to 3 hops, loop-safe).
     * 2. Strips known tracking parameters based on cleaner level and exceptions.
     */
    fun clean(url: String, level: CleanerLevel = CleanerLevel.STANDARD): CleanResult {
        val trimmed = url.trim()
        val parsedOriginal = ParsedUrl.parse(trimmed) ?: return CleanResult(
            cleanedUrl = trimmed,
            originalUrl = trimmed,
            removedParams = emptyList(),
            unwrapped = false
        )

        // Step 1: Unwrap redirect wrappers
        val unwrapResult = unwrapRedirects(trimmed)
        val workingUrl = unwrapResult.first
        val wasUnwrapped = unwrapResult.second

        if (level == CleanerLevel.OFF) {
            return CleanResult(
                cleanedUrl = workingUrl,
                originalUrl = trimmed,
                removedParams = emptyList(),
                unwrapped = wasUnwrapped
            )
        }

        val parsed = ParsedUrl.parse(workingUrl) ?: return CleanResult(
            cleanedUrl = workingUrl,
            originalUrl = trimmed,
            removedParams = emptyList(),
            unwrapped = wasUnwrapped
        )

        // Step 2: Strip tracking parameters
        val host = parsed.asciiHost
        val safeExceptionsForHost = getExceptionsForHost(host)
        val domainTrackingForHost = getDomainTrackingForHost(host)

        val remainingParams = mutableListOf<QueryParam>()
        val removedParamNames = mutableListOf<String>()

        for (param in parsed.queryParams) {
            val keyLower = param.key.lowercase()

            // Check safe exceptions first
            if (safeExceptionsForHost.contains(keyLower)) {
                remainingParams.add(param)
                continue
            }

            // Check global tracking params
            val isGlobalTracking = config.globalTrackingParams.any { it.equals(keyLower, ignoreCase = true) }
            val isDomainTracking = domainTrackingForHost.contains(keyLower)

            var isAggressiveTracking = false
            if (level == CleanerLevel.AGGRESSIVE) {
                isAggressiveTracking = AGGRESSIVE_PREFIXES.any { keyLower.startsWith(it) } ||
                    AGGRESSIVE_SUBSTRINGS.any { keyLower.contains(it) }
            }

            if (isGlobalTracking || isDomainTracking || isAggressiveTracking) {
                removedParamNames.add(param.key)
            } else {
                remainingParams.add(param)
            }
        }

        val cleanedUrl = if (removedParamNames.isNotEmpty() || (parsed.queryParams.isEmpty() && workingUrl.contains("?"))) {
            parsed.buildUrl(remainingParams)
        } else {
            workingUrl
        }

        return CleanResult(
            cleanedUrl = cleanedUrl,
            originalUrl = trimmed,
            removedParams = removedParamNames,
            unwrapped = wasUnwrapped
        )
    }

    private fun unwrapRedirects(initialUrl: String): Pair<String, Boolean> {
        var currentUrl = initialUrl
        val visited = mutableSetOf<String>()
        var hops = 0
        var unwrappedAny = false

        while (hops < MAX_UNWRAP_HOPS) {
            if (!visited.add(currentUrl)) {
                // Loop detected
                break
            }

            val parsed = ParsedUrl.parse(currentUrl) ?: break
            val wrapper = findMatchingWrapper(parsed) ?: break

            // Find the redirect parameter
            val paramValue = parsed.queryParams.find { it.key.equals(wrapper.param, ignoreCase = true) }?.value
                ?: break

            val decodedTarget = tryDecodeUrl(paramValue) ?: break

            // Target must be a valid http/https URL
            if (!decodedTarget.startsWith("http://", ignoreCase = true) &&
                !decodedTarget.startsWith("https://", ignoreCase = true)
            ) {
                break
            }

            currentUrl = decodedTarget
            unwrappedAny = true
            hops++
        }

        return Pair(currentUrl, unwrappedAny)
    }

    private fun findMatchingWrapper(parsed: ParsedUrl): RedirectWrapper? {
        val host = parsed.asciiHost
        val path = parsed.path

        return config.redirectWrappers.firstOrNull { wrapper ->
            val wrapperHost = ParsedUrl.normalizeHost(wrapper.domain)
            val hostMatches = hostMatchesPattern(host, wrapperHost)

            val pathMatches = if (wrapper.path != null) {
                path.startsWith(wrapper.path, ignoreCase = true)
            } else {
                true
            }

            hostMatches && pathMatches
        }
    }

    private fun getExceptionsForHost(host: String): Set<String> {
        val result = mutableSetOf<String>()
        for ((domainKey, exceptions) in config.safeExceptions) {
            val normalizedKey = ParsedUrl.normalizeHost(domainKey)
            if (hostMatchesPattern(host, normalizedKey)) {
                result.addAll(exceptions.map { it.lowercase() })
            }
        }
        return result
    }

    private fun getDomainTrackingForHost(host: String): Set<String> {
        val result = mutableSetOf<String>()
        for ((domainKey, params) in config.domainTrackingParams) {
            val normalizedKey = ParsedUrl.normalizeHost(domainKey)
            if (hostMatchesPattern(host, normalizedKey)) {
                result.addAll(params.map { it.lowercase() })
            }
        }
        return result
    }

    private fun hostMatchesPattern(host: String, pattern: String): Boolean {
        val root = if (pattern.startsWith("*.")) pattern.substring(2) else pattern
        return host.equals(root, ignoreCase = true) || host.endsWith(".$root", ignoreCase = true)
    }

    private fun tryDecodeUrl(raw: String): String? {
        val decoded = try {
            URLDecoder.decode(raw, StandardCharsets.UTF_8.name())
        } catch (_: Exception) {
            raw
        }
        return decoded.takeIf { it.startsWith("http://", ignoreCase = true) || it.startsWith("https://", ignoreCase = true) }
    }
}
