package com.linkpilot.core.matcher

import com.linkpilot.core.cleaner.ParsedUrl
import com.linkpilot.core.model.Action
import com.linkpilot.core.model.Decision
import com.linkpilot.core.model.Mode
import com.linkpilot.core.model.PickerReason
import com.linkpilot.core.model.Rule
import com.linkpilot.core.model.Settings
import java.util.regex.Pattern
import java.util.regex.PatternSyntaxException

class RegexTimeoutException(message: String) : RuntimeException(message)

private class GuardedCharSequence(
    private val inner: CharSequence,
    private val maxOps: Int = 100_000
) : CharSequence {
    private var ops = 0

    override val length: Int get() = inner.length

    override fun get(index: Int): Char {
        if (++ops > maxOps) {
            throw RegexTimeoutException("Regex evaluation exceeded step limit")
        }
        return inner[index]
    }

    override fun subSequence(startIndex: Int, endIndex: Int): CharSequence {
        return GuardedCharSequence(inner.subSequence(startIndex, endIndex), maxOps - ops)
    }
}

enum class Specificity(val level: Int) {
    SOURCE_ONLY(1),
    WILDCARD_DOMAIN(2),
    EXACT_DOMAIN(3),
    URL_REGEX(4)
}

data class MatchEvaluation(
    val rule: Rule,
    val matches: Boolean,
    val specificity: Specificity
)

class RuleMatcher {

    companion object {
        private const val MAX_REGEX_LENGTH = 256
    }

    /**
     * Finds the winning rule for a given URL and source package, or null if no rules match.
     * Respects priority, then specificity, then creation order.
     */
    fun findWinningRule(url: String, sourcePackage: String?, rules: List<Rule>): Rule? {
        val parsed = ParsedUrl.parse(url) ?: return null

        val candidateMatches = rules
            .filter { it.enabled }
            .mapNotNull { rule ->
                val eval = evaluateRule(rule, parsed, url, sourcePackage)
                if (eval.matches) eval else null
            }

        if (candidateMatches.isEmpty()) return null

        // Sort: highest priority first, then highest specificity first, then oldest createdAtEpochMs
        return candidateMatches
            .sortedWith(
                compareByDescending<MatchEvaluation> { it.rule.priority }
                    .thenByDescending { it.specificity.level }
                    .thenBy { it.rule.createdAtEpochMs }
                    .thenBy { it.rule.id }
            )
            .first()
            .rule
    }

    /**
     * Resolves the decision based on matching rules and global settings.
     */
    fun resolveDecision(
        url: String,
        sourcePackage: String?,
        rules: List<Rule>,
        settings: Settings
    ): Decision {
        val winningRule = findWinningRule(url, sourcePackage, rules)

        if (winningRule != null) {
            return when (val action = winningRule.action) {
                is Action.OpenInBrowser -> Decision.Launch(winningRule, action)
                is Action.OpenInApp -> Decision.Launch(winningRule, action)
                is Action.AlwaysAsk -> Decision.ShowPicker(PickerReason.RULE_ACTION_ALWAYS_ASK)
            }
        }

        // Fallback: Global default browser if configured
        val globalDefault = settings.globalDefaultBrowser
        if (!globalDefault.isNullOrBlank()) {
            return Decision.Launch(
                rule = null,
                action = Action.OpenInBrowser(globalDefault, Mode.NORMAL)
            )
        }

        // Final fallback: Show picker
        return Decision.ShowPicker(PickerReason.NO_RULE_MATCH)
    }

    fun evaluateRule(
        rule: Rule,
        parsedUrl: ParsedUrl,
        rawUrl: String,
        sourcePackage: String?
    ): MatchEvaluation {
        val matchDef = rule.match

        // Condition 1: Source package check
        val sourceMatches = if (matchDef.sourcePackages.isNotEmpty()) {
            sourcePackage != null && matchDef.sourcePackages.any { it.equals(sourcePackage, ignoreCase = true) }
        } else {
            true
        }
        if (!sourceMatches) {
            return MatchEvaluation(rule, false, Specificity.SOURCE_ONLY)
        }

        // Condition 2: Regex check
        var regexMatches = true
        var hasRegex = false
        if (!matchDef.urlRegex.isNullOrBlank()) {
            hasRegex = true
            regexMatches = evaluateRegexSafely(matchDef.urlRegex, rawUrl)
            if (!regexMatches) {
                return MatchEvaluation(rule, false, Specificity.URL_REGEX)
            }
        }

        // Condition 3: Domain check
        var domainMatches = true
        var matchedDomainType: Specificity? = null

        if (matchDef.domains.isNotEmpty()) {
            val host = parsedUrl.asciiHost
            var anyDomainMatched = false

            for (domainPattern in matchDef.domains) {
                val normalizedPattern = ParsedUrl.normalizeHost(domainPattern)
                if (normalizedPattern.startsWith("*.")) {
                    val root = normalizedPattern.substring(2)
                    if (host.equals(root, ignoreCase = true) || host.endsWith(".$root", ignoreCase = true)) {
                        anyDomainMatched = true
                        if (matchedDomainType == null || matchedDomainType.level < Specificity.WILDCARD_DOMAIN.level) {
                            matchedDomainType = Specificity.WILDCARD_DOMAIN
                        }
                    }
                } else {
                    if (host.equals(normalizedPattern, ignoreCase = true)) {
                        anyDomainMatched = true
                        matchedDomainType = Specificity.EXACT_DOMAIN
                    }
                }
            }

            domainMatches = anyDomainMatched
            if (!domainMatches) {
                return MatchEvaluation(rule, false, Specificity.EXACT_DOMAIN)
            }
        }

        val finalSpecificity = when {
            hasRegex -> Specificity.URL_REGEX
            matchedDomainType == Specificity.EXACT_DOMAIN -> Specificity.EXACT_DOMAIN
            matchedDomainType == Specificity.WILDCARD_DOMAIN -> Specificity.WILDCARD_DOMAIN
            matchDef.sourcePackages.isNotEmpty() -> Specificity.SOURCE_ONLY
            else -> Specificity.SOURCE_ONLY
        }

        return MatchEvaluation(rule, true, finalSpecificity)
    }

    private fun evaluateRegexSafely(regexStr: String, target: String): Boolean {
        if (regexStr.length > MAX_REGEX_LENGTH) return false

        return try {
            val pattern = Pattern.compile(regexStr)
            val guardedInput = GuardedCharSequence(target)
            pattern.matcher(guardedInput).find()
        } catch (_: RegexTimeoutException) {
            false
        } catch (_: PatternSyntaxException) {
            false
        } catch (_: Exception) {
            false
        }
    }
}
