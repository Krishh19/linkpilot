package com.linkpilot.core.rules

import com.linkpilot.core.matcher.RuleMatcher
import com.linkpilot.core.model.Action
import com.linkpilot.core.model.Mode
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RuleDraftsTest {

    private val matcher = RuleMatcher()

    @Test
    fun testSiteRuleFromWwwHostCoversApexAndSubdomains() {
        val rule = RuleDrafts.forSite("www.reddit.com", "www.reddit.com", "org.mozilla.firefox")

        assertEquals(listOf("*.reddit.com"), rule.match.domains)
        assertTrue(matcher.findWinningRule("https://reddit.com/r/android", null, listOf(rule)) != null)
        assertTrue(matcher.findWinningRule("https://www.reddit.com/r/android", null, listOf(rule)) != null)
        assertTrue(matcher.findWinningRule("https://old.reddit.com/r/android", null, listOf(rule)) != null)
        assertNull(matcher.findWinningRule("https://notreddit.com/r/android", null, listOf(rule)))
    }

    @Test
    fun testSiteRuleFromPlainHostCoversSubdomains() {
        val rule = RuleDrafts.forSite("example.com", "example.com", "com.android.chrome")

        assertEquals(listOf("*.example.com"), rule.match.domains)
        assertTrue(matcher.findWinningRule("https://example.com/page", null, listOf(rule)) != null)
        assertTrue(matcher.findWinningRule("https://docs.example.com/page", null, listOf(rule)) != null)
    }

    @Test
    fun testSiteRuleKeepsChosenBrowserAndMode() {
        val rule = RuleDrafts.forSite("example.com", "example.com", "org.mozilla.firefox", Mode.PRIVATE)
        val action = rule.action as Action.OpenInBrowser

        assertEquals("org.mozilla.firefox", action.pkg)
        assertEquals(Mode.PRIVATE, action.mode)
        assertEquals(10, rule.priority)
    }

    @Test
    fun testSourceAppRuleMatchesOnlyThatSource() {
        val rule = RuleDrafts.forSourceApp("com.reddit.frontpage", "com.android.chrome")

        assertTrue(
            matcher.findWinningRule("https://example.com", "com.reddit.frontpage", listOf(rule)) != null
        )
        assertNull(
            matcher.findWinningRule("https://example.com", "com.twitter.android", listOf(rule))
        )
    }
}
