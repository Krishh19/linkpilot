package com.linkpilot.core.matcher

import com.linkpilot.core.cleaner.ParsedUrl
import com.linkpilot.core.model.Action
import com.linkpilot.core.model.CleanerLevel
import com.linkpilot.core.model.Decision
import com.linkpilot.core.model.Match
import com.linkpilot.core.model.Mode
import com.linkpilot.core.model.PickerReason
import com.linkpilot.core.model.Rule
import com.linkpilot.core.model.Settings
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class RuleMatcherTest {

    private lateinit var matcher: RuleMatcher

    @Before
    fun setUp() {
        matcher = RuleMatcher()
    }

    private fun createRule(
        id: String,
        priority: Int = 0,
        domains: List<String> = emptyList(),
        urlRegex: String? = null,
        sourcePackages: List<String> = emptyList(),
        action: Action = Action.OpenInBrowser("com.test.browser", Mode.NORMAL),
        enabled: Boolean = true,
        createdAt: Long = 1000L
    ): Rule {
        return Rule(
            id = id,
            priority = priority,
            match = Match(domains, urlRegex, sourcePackages),
            action = action,
            enabled = enabled,
            createdAtEpochMs = createdAt
        )
    }

    // --- Domain Condition Tests ---

    @Test
    fun testExactDomainMatches() {
        val rule = createRule("1", domains = listOf("reddit.com"))
        val winning = matcher.findWinningRule("https://reddit.com/r/android", null, listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testExactDomainDoesNotMatchSubdomain() {
        val rule = createRule("1", domains = listOf("reddit.com"))
        val winning = matcher.findWinningRule("https://old.reddit.com/r/android", null, listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testExactDomainDoesNotMatchParent() {
        val rule = createRule("1", domains = listOf("sub.example.com"))
        val winning = matcher.findWinningRule("https://example.com", null, listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testWildcardDomainMatchesApex() {
        val rule = createRule("1", domains = listOf("*.reddit.com"))
        val winning = matcher.findWinningRule("https://reddit.com/r/technology", null, listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testWildcardDomainMatchesSubdomain() {
        val rule = createRule("1", domains = listOf("*.reddit.com"))
        val winning = matcher.findWinningRule("https://old.reddit.com/r/android", null, listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testWildcardDomainMatchesMultiLevelSubdomain() {
        val rule = createRule("1", domains = listOf("*.reddit.com"))
        val winning = matcher.findWinningRule("https://v.preview.reddit.com/video", null, listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testWildcardDomainDoesNotMatchLookalikeDomain() {
        val rule = createRule("1", domains = listOf("*.reddit.com"))
        val winning = matcher.findWinningRule("https://notreddit.com/page", null, listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testWildcardDomainDoesNotMatchAttackerSuffix() {
        val rule = createRule("1", domains = listOf("*.reddit.com"))
        val winning = matcher.findWinningRule("https://reddit.com.attacker.com/steal", null, listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testWildcardDomainDoesNotMatchHyphenatedDomain() {
        val rule = createRule("1", domains = listOf("*.reddit.com"))
        val winning = matcher.findWinningRule("https://my-reddit.com", null, listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testWildcardDomainDoesNotMatchPartialPrefix() {
        val rule = createRule("1", domains = listOf("*.reddit.com"))
        val winning = matcher.findWinningRule("https://fakereddit.com", null, listOf(rule))
        assertNull(winning)
    }

    // --- IDN and Punycode Tests ---

    @Test
    fun testIdnPunycodeExactDomainMatching() {
        // "münchen.de" in punycode is "xn--mnchen-3ya.de"
        val rule = createRule("1", domains = listOf("münchen.de"))
        val winning = matcher.findWinningRule("https://xn--mnchen-3ya.de/rathaus", null, listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testIdnPunycodeWildcardMatching() {
        val rule = createRule("1", domains = listOf("*.münchen.de"))
        val winning = matcher.findWinningRule("https://portal.xn--mnchen-3ya.de/service", null, listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testCaseInsensitiveDomainMatching() {
        val rule = createRule("1", domains = listOf("EXAMPLE.COM"))
        val winning = matcher.findWinningRule("https://example.com/item", null, listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testPortHandlingInDomainMatching() {
        val rule = createRule("1", domains = listOf("example.com"))
        val winning = matcher.findWinningRule("https://example.com:8080/dashboard", null, listOf(rule))
        assertEquals("1", winning?.id)
    }

    // --- Priority and Specificity Precedence Tests ---

    @Test
    fun testPriorityPrecedenceHigherPriorityWins() {
        val ruleLow = createRule("low", priority = 10, domains = listOf("example.com"))
        val ruleHigh = createRule("high", priority = 100, domains = listOf("*.example.com"))

        val winning = matcher.findWinningRule("https://example.com", null, listOf(ruleLow, ruleHigh))
        assertEquals("high", winning?.id)
    }

    @Test
    fun testPriorityPrecedenceEqualPriorityUsesSpecificity() {
        val ruleWildcard = createRule("wildcard", priority = 50, domains = listOf("*.example.com"))
        val ruleExact = createRule("exact", priority = 50, domains = listOf("example.com"))

        val winning = matcher.findWinningRule("https://example.com", null, listOf(ruleWildcard, ruleExact))
        assertEquals("exact", winning?.id)
    }

    @Test
    fun testSpecificityRegexBeatsExactDomain() {
        val ruleExact = createRule("exact", priority = 0, domains = listOf("example.com"))
        val ruleRegex = createRule("regex", priority = 0, urlRegex = "https://example\\.com/special.*")

        val winning = matcher.findWinningRule("https://example.com/special_page", null, listOf(ruleExact, ruleRegex))
        assertEquals("regex", winning?.id)
    }

    @Test
    fun testSpecificityExactDomainBeatsWildcard() {
        val ruleWildcard = createRule("wildcard", priority = 0, domains = listOf("*.example.com"))
        val ruleExact = createRule("exact", priority = 0, domains = listOf("sub.example.com"))

        val winning = matcher.findWinningRule("https://sub.example.com/index", null, listOf(ruleWildcard, ruleExact))
        assertEquals("exact", winning?.id)
    }

    @Test
    fun testSpecificityWildcardBeatsSourceOnly() {
        val ruleSource = createRule("source", priority = 0, sourcePackages = listOf("com.reddit.app"))
        val ruleWildcard = createRule("wildcard", priority = 0, domains = listOf("*.example.com"))

        val winning = matcher.findWinningRule("https://sub.example.com", "com.reddit.app", listOf(ruleSource, ruleWildcard))
        assertEquals("wildcard", winning?.id)
    }

    @Test
    fun testSpecificityTieBreakerUsesCreationTime() {
        val ruleOlder = createRule("older", priority = 0, domains = listOf("example.com"), createdAt = 100L)
        val ruleNewer = createRule("newer", priority = 0, domains = listOf("example.com"), createdAt = 200L)

        val winning = matcher.findWinningRule("https://example.com", null, listOf(ruleNewer, ruleOlder))
        assertEquals("older", winning?.id)
    }

    @Test
    fun testSpecificityTieBreakerUsesRuleId() {
        val ruleA = createRule("a", priority = 0, domains = listOf("example.com"), createdAt = 100L)
        val ruleB = createRule("b", priority = 0, domains = listOf("example.com"), createdAt = 100L)

        val winning = matcher.findWinningRule("https://example.com", null, listOf(ruleB, ruleA))
        assertEquals("a", winning?.id)
    }

    // --- Source Package Tests ---

    @Test
    fun testSourcePackageMatchingExact() {
        val rule = createRule("1", sourcePackages = listOf("com.twitter.android"))
        val winning = matcher.findWinningRule("https://example.com", "com.twitter.android", listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testSourcePackageMismatchDoesNotMatch() {
        val rule = createRule("1", sourcePackages = listOf("com.twitter.android"))
        val winning = matcher.findWinningRule("https://example.com", "com.facebook.katana", listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testSourcePackageNullWhenRuleRequiresSourceDoesNotMatch() {
        val rule = createRule("1", sourcePackages = listOf("com.twitter.android"))
        val winning = matcher.findWinningRule("https://example.com", null, listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testSourcePackageEmptyRuleMatchesAnySource() {
        val rule = createRule("1", domains = listOf("example.com"), sourcePackages = emptyList())
        val winning = matcher.findWinningRule("https://example.com", "com.random.app", listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testSourcePackageEmptyRuleMatchesNullSource() {
        val rule = createRule("1", domains = listOf("example.com"), sourcePackages = emptyList())
        val winning = matcher.findWinningRule("https://example.com", null, listOf(rule))
        assertEquals("1", winning?.id)
    }

    // --- AND Condition Combinations ---

    @Test
    fun testAndConditionDomainAndSourceBothMustMatch() {
        val rule = createRule("1", domains = listOf("*.reddit.com"), sourcePackages = listOf("com.twitter.android"))
        val winning = matcher.findWinningRule("https://reddit.com", "com.twitter.android", listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testAndConditionDomainMatchesSourceMismatchDoesNotMatch() {
        val rule = createRule("1", domains = listOf("*.reddit.com"), sourcePackages = listOf("com.twitter.android"))
        val winning = matcher.findWinningRule("https://reddit.com", "com.other.app", listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testAndConditionSourceMatchesDomainMismatchDoesNotMatch() {
        val rule = createRule("1", domains = listOf("*.reddit.com"), sourcePackages = listOf("com.twitter.android"))
        val winning = matcher.findWinningRule("https://github.com", "com.twitter.android", listOf(rule))
        assertNull(winning)
    }

    // --- URL Regex Condition Tests ---

    @Test
    fun testUrlRegexMatches() {
        val rule = createRule("1", urlRegex = "https://github\\.com/[^/]+/[^/]+/issues/\\d+")
        val winning = matcher.findWinningRule("https://github.com/flutter/flutter/issues/12345", null, listOf(rule))
        assertEquals("1", winning?.id)
    }

    @Test
    fun testUrlRegexMismatch() {
        val rule = createRule("1", urlRegex = "https://github\\.com/[^/]+/[^/]+/issues/\\d+")
        val winning = matcher.findWinningRule("https://github.com/flutter/flutter/pull/12345", null, listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testUrlRegexLengthGuardRejectsLongPattern() {
        // Construct pattern exceeding 256 characters
        val longPattern = "a".repeat(260)
        val rule = createRule("1", urlRegex = longPattern)
        val winning = matcher.findWinningRule("https://example.com/a", null, listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testUrlRegexMalformedPatternHandledSafely() {
        val rule = createRule("1", urlRegex = "[a-z") // Unclosed bracket
        val winning = matcher.findWinningRule("https://example.com", null, listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testUrlRegexReDosCatastrophicBacktrackingGuardedWithoutHanging() {
        // Classic catastrophic backtracking pattern: (a+)+$ on a string of many 'a's ending in 'b'
        val redosRegex = "(a+)+$"
        val rule = createRule("1", urlRegex = redosRegex)
        val evilUrl = "https://example.com/" + "a".repeat(30) + "b"

        val startTime = System.currentTimeMillis()
        val winning = matcher.findWinningRule(evilUrl, null, listOf(rule))
        val elapsed = System.currentTimeMillis() - startTime

        assertNull(winning)
        assertTrue("ReDoS evaluation should be bounded (< 500ms), took ${elapsed}ms", elapsed < 500)
    }

    // --- Action and Decision Tests ---

    @Test
    fun testDisabledRuleIsIgnored() {
        val rule = createRule("1", domains = listOf("example.com"), enabled = false)
        val winning = matcher.findWinningRule("https://example.com", null, listOf(rule))
        assertNull(winning)
    }

    @Test
    fun testMultipleRulesOnlyEnabledMatches() {
        val disabled = createRule("dis", priority = 100, domains = listOf("example.com"), enabled = false)
        val enabled = createRule("en", priority = 10, domains = listOf("example.com"), enabled = true)

        val winning = matcher.findWinningRule("https://example.com", null, listOf(disabled, enabled))
        assertEquals("en", winning?.id)
    }

    @Test
    fun testActionOpenInBrowserNormalMode() {
        val rule = createRule("1", domains = listOf("example.com"), action = Action.OpenInBrowser("org.mozilla.firefox", Mode.NORMAL))
        val decision = matcher.resolveDecision("https://example.com", null, listOf(rule), Settings())

        assertTrue(decision is Decision.Launch)
        val launch = decision as Decision.Launch
        val action = launch.action as Action.OpenInBrowser
        assertEquals("org.mozilla.firefox", action.pkg)
        assertEquals(Mode.NORMAL, action.mode)
    }

    @Test
    fun testActionOpenInBrowserPrivateMode() {
        val rule = createRule("1", domains = listOf("example.com"), action = Action.OpenInBrowser("org.mozilla.firefox", Mode.PRIVATE))
        val decision = matcher.resolveDecision("https://example.com", null, listOf(rule), Settings())

        assertTrue(decision is Decision.Launch)
        val launch = decision as Decision.Launch
        val action = launch.action as Action.OpenInBrowser
        assertEquals("org.mozilla.firefox", action.pkg)
        assertEquals(Mode.PRIVATE, action.mode)
    }

    @Test
    fun testActionOpenInApp() {
        val rule = createRule("1", domains = listOf("reddit.com"), action = Action.OpenInApp("com.reddit.frontpage"))
        val decision = matcher.resolveDecision("https://reddit.com", null, listOf(rule), Settings())

        assertTrue(decision is Decision.Launch)
        val launch = decision as Decision.Launch
        assertEquals("com.reddit.frontpage", (launch.action as Action.OpenInApp).pkg)
    }

    @Test
    fun testActionAlwaysAskReturnsShowPicker() {
        val rule = createRule("1", domains = listOf("example.com"), action = Action.AlwaysAsk)
        val decision = matcher.resolveDecision("https://example.com", null, listOf(rule), Settings())

        assertTrue(decision is Decision.ShowPicker)
        assertEquals(PickerReason.RULE_ACTION_ALWAYS_ASK, (decision as Decision.ShowPicker).reason)
    }

    @Test
    fun testNoRuleMatchFallbackToGlobalDefaultBrowser() {
        val settings = Settings(globalDefaultBrowser = "com.brave.browser")
        val decision = matcher.resolveDecision("https://unknown.org", null, emptyList(), settings)

        assertTrue(decision is Decision.Launch)
        val launch = decision as Decision.Launch
        assertNull(launch.rule)
        assertEquals("com.brave.browser", (launch.action as Action.OpenInBrowser).pkg)
    }

    @Test
    fun testNoRuleMatchFallbackToPickerWhenNoDefaultBrowser() {
        val settings = Settings(globalDefaultBrowser = null)
        val decision = matcher.resolveDecision("https://unknown.org", null, emptyList(), settings)

        assertTrue(decision is Decision.ShowPicker)
        assertEquals(PickerReason.NO_RULE_MATCH, (decision as Decision.ShowPicker).reason)
    }

    @Test
    fun testEmptyRulesListFallbackToPicker() {
        val decision = matcher.resolveDecision("https://example.com", null, emptyList(), Settings())
        assertTrue(decision is Decision.ShowPicker)
    }

    // --- Domain Variants and Multi-domain Tests ---

    @Test
    fun testMultipleWildcardDomainsInSingleRule() {
        val rule = createRule("1", domains = listOf("*.reddit.com", "*.redd.it"))
        val win1 = matcher.findWinningRule("https://v.redd.it/abc", null, listOf(rule))
        val win2 = matcher.findWinningRule("https://reddit.com/r/all", null, listOf(rule))

        assertEquals("1", win1?.id)
        assertEquals("1", win2?.id)
    }

    @Test
    fun testMultipleExactDomainsInSingleRule() {
        val rule = createRule("1", domains = listOf("x.com", "twitter.com"))
        val win1 = matcher.findWinningRule("https://x.com/status", null, listOf(rule))
        val win2 = matcher.findWinningRule("https://twitter.com/status", null, listOf(rule))

        assertEquals("1", win1?.id)
        assertEquals("1", win2?.id)
    }

    @Test
    fun testCombinedWildcardAndExactDomainsInSingleRule() {
        val rule = createRule("1", domains = listOf("*.youtube.com", "youtu.be"))
        val win1 = matcher.findWinningRule("https://m.youtube.com/watch", null, listOf(rule))
        val win2 = matcher.findWinningRule("https://youtu.be/123", null, listOf(rule))

        assertEquals("1", win1?.id)
        assertEquals("1", win2?.id)
    }

    @Test
    fun testMultipleSourcePackagesInSingleRule() {
        val rule = createRule("1", sourcePackages = listOf("com.whatsapp", "org.telegram.messenger"))
        val win1 = matcher.findWinningRule("https://example.com", "com.whatsapp", listOf(rule))
        val win2 = matcher.findWinningRule("https://example.com", "org.telegram.messenger", listOf(rule))

        assertEquals("1", win1?.id)
        assertEquals("1", win2?.id)
    }

    @Test
    fun testQueryStringIgnoredDuringDomainMatching() {
        val rule = createRule("1", domains = listOf("example.com"))
        val win = matcher.findWinningRule("https://example.com/search?q=reddit.com&tag=test", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testFragmentIgnoredDuringDomainMatching() {
        val rule = createRule("1", domains = listOf("example.com"))
        val win = matcher.findWinningRule("https://example.com/#reddit.com", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testHttpSchemeMatches() {
        val rule = createRule("1", domains = listOf("insecure.org"))
        val win = matcher.findWinningRule("http://insecure.org/page", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testHttpsSchemeMatches() {
        val rule = createRule("1", domains = listOf("secure.org"))
        val win = matcher.findWinningRule("https://secure.org/page", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testComplexSubdomainWithDash() {
        val rule = createRule("1", domains = listOf("*.my-service.corp.com"))
        val win = matcher.findWinningRule("https://dev-01.my-service.corp.com/api", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testNumericIpHostMatching() {
        val rule = createRule("1", domains = listOf("192.168.1.1"))
        val win = matcher.findWinningRule("http://192.168.1.1:8080/setup", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testLocalhostMatching() {
        val rule = createRule("1", domains = listOf("localhost"))
        val win = matcher.findWinningRule("http://localhost:3000/app", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testApexMatchWithTrailingSlash() {
        val rule = createRule("1", domains = listOf("*.example.com"))
        val win = matcher.findWinningRule("https://example.com/", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testApexMatchWithoutTrailingSlash() {
        val rule = createRule("1", domains = listOf("*.example.com"))
        val win = matcher.findWinningRule("https://example.com", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testPathPrefixWithRegex() {
        val rule = createRule("1", urlRegex = "https://example\\.com/admin/.*")
        val win = matcher.findWinningRule("https://example.com/admin/dashboard", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testQueryParameterWithRegex() {
        val rule = createRule("1", urlRegex = ".*[?&]mode=debug.*")
        val win = matcher.findWinningRule("https://example.com/test?lang=en&mode=debug", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testUnicodePathWithRegex() {
        val rule = createRule("1", urlRegex = ".*café.*")
        val win = matcher.findWinningRule("https://example.com/menu/café", null, listOf(rule))
        assertEquals("1", win?.id)
    }

    @Test
    fun testCaseInsensitiveSourcePackage() {
        val rule = createRule("1", sourcePackages = listOf("com.example.APP"))
        val win = matcher.findWinningRule("https://example.com", "com.example.app", listOf(rule))
        assertEquals("1", win?.id)
    }
}
