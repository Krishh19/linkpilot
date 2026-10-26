package com.linkpilot.core.engine

import com.linkpilot.core.model.Action
import com.linkpilot.core.model.CleanerConfig
import com.linkpilot.core.model.CleanerLevel
import com.linkpilot.core.model.Decision
import com.linkpilot.core.model.Match
import com.linkpilot.core.model.Mode
import com.linkpilot.core.model.PickerReason
import com.linkpilot.core.model.RedirectWrapper
import com.linkpilot.core.model.Rule
import com.linkpilot.core.model.Settings
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class LinkRouterEngineTest {

    private lateinit var engine: LinkRouterEngine

    @Before
    fun setUp() {
        val config = CleanerConfig(
            version = 1,
            globalTrackingParams = listOf("utm_source", "fbclid"),
            domainTrackingParams = mapOf(
                "twitter.com" to listOf("s", "t")
            ),
            redirectWrappers = listOf(
                RedirectWrapper("l.facebook.com", null, "u")
            )
        )
        engine = LinkRouterEngine.create(config)
    }

    @Test
    fun testRejectOversizedUrl() {
        val oversized = "https://example.com/path?" + "a".repeat(8200)
        val result = engine.route(oversized, null, emptyList(), Settings())
        assertTrue(result.decision is Decision.ShowPicker)
        assertEquals(PickerReason.REJECTED_INPUT, (result.decision as Decision.ShowPicker).reason)
    }

    @Test
    fun testRejectNonHttpSchemeFtp() {
        val result = engine.route("ftp://ftp.example.com/file.txt", null, emptyList(), Settings())
        assertTrue(result.decision is Decision.ShowPicker)
        assertEquals(PickerReason.REJECTED_INPUT, (result.decision as Decision.ShowPicker).reason)
    }

    @Test
    fun testRejectNonHttpSchemeJavascript() {
        val result = engine.route("javascript:alert(1)", null, emptyList(), Settings())
        assertTrue(result.decision is Decision.ShowPicker)
        assertEquals(PickerReason.REJECTED_INPUT, (result.decision as Decision.ShowPicker).reason)
    }

    @Test
    fun testRejectNonHttpSchemeIntent() {
        val result = engine.route("intent:#Intent;action=android.intent.action.VIEW;end", null, emptyList(), Settings())
        assertTrue(result.decision is Decision.ShowPicker)
        assertEquals(PickerReason.REJECTED_INPUT, (result.decision as Decision.ShowPicker).reason)
    }

    @Test
    fun testRejectEmptyUrl() {
        val result = engine.route("   ", null, emptyList(), Settings())
        assertTrue(result.decision is Decision.ShowPicker)
        assertEquals(PickerReason.REJECTED_INPUT, (result.decision as Decision.ShowPicker).reason)
    }

    @Test
    fun testEndToEndCleanAndMatch() {
        val redditRule = Rule(
            id = "reddit",
            priority = 10,
            match = Match(domains = listOf("*.reddit.com")),
            action = Action.OpenInBrowser("org.mozilla.firefox", Mode.NORMAL)
        )

        // Raw URL has UTM tracker
        val raw = "https://old.reddit.com/r/android?utm_source=twitter"
        val result = engine.route(raw, null, listOf(redditRule), Settings())

        assertEquals("https://old.reddit.com/r/android", result.cleanedUrl)
        assertEquals(raw, result.originalUrl)
        assertEquals(listOf("utm_source"), result.removedParams)
        assertTrue(result.decision is Decision.Launch)
        val launch = result.decision as Decision.Launch
        assertEquals("reddit", launch.rule?.id)
        assertEquals("org.mozilla.firefox", (launch.action as Action.OpenInBrowser).pkg)
    }

    @Test
    fun testEndToEndUnwrapCleanAndMatch() {
        val targetRule = Rule(
            id = "target",
            priority = 10,
            match = Match(domains = listOf("clean.example.com")),
            action = Action.OpenInBrowser("com.brave.browser", Mode.PRIVATE)
        )

        // Facebook linkshim wrapping clean.example.com with utm_source
        val wrapped = "https://l.facebook.com/l.php?u=https%3A%2F%2Fclean.example.com%2Fpost%3Futm_source%3Dfeed"
        val result = engine.route(wrapped, null, listOf(targetRule), Settings())

        assertEquals("https://clean.example.com/post", result.cleanedUrl)
        assertEquals(listOf("utm_source"), result.removedParams)
        assertTrue(result.decision is Decision.Launch)
        val launch = result.decision as Decision.Launch
        assertEquals("target", launch.rule?.id)
        assertEquals(Mode.PRIVATE, (launch.action as Action.OpenInBrowser).mode)
    }

    @Test
    fun testEndToEndFallbackToGlobalDefault() {
        val settings = Settings(globalDefaultBrowser = "com.android.chrome")
        val result = engine.route("https://unknown.com/page", null, emptyList(), settings)

        assertTrue(result.decision is Decision.Launch)
        val launch = result.decision as Decision.Launch
        assertEquals("com.android.chrome", (launch.action as Action.OpenInBrowser).pkg)
    }

    @Test
    fun testEndToEndFallbackToPicker() {
        val settings = Settings(globalDefaultBrowser = null)
        val result = engine.route("https://unknown.com/page", null, emptyList(), settings)

        assertTrue(result.decision is Decision.ShowPicker)
        assertEquals(PickerReason.NO_RULE_MATCH, (result.decision as Decision.ShowPicker).reason)
    }
}
