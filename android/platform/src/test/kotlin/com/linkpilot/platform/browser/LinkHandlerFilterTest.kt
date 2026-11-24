package com.linkpilot.platform.browser

import org.junit.Assert.assertEquals
import org.junit.Test

class LinkHandlerFilterTest {

    @Test
    fun `excludes browsers and the current app`() {
        val candidates = listOf(
            LinkHandlerApp("com.reddit.frontpage", "Reddit", null),
            LinkHandlerApp("org.mozilla.firefox", "Firefox", null),
            LinkHandlerApp("com.linkpilot.app", "LinkPilot", null)
        )

        val result = filterLinkHandlers(
            candidates = candidates,
            excludedPackages = setOf("org.mozilla.firefox", "com.linkpilot.app")
        )

        assertEquals(listOf("com.reddit.frontpage"), result.map { it.packageName })
    }

    @Test
    fun `keeps one entry per package and puts the default handler first`() {
        val candidates = listOf(
            LinkHandlerApp("com.instagram.android", "Instagram", null),
            LinkHandlerApp("com.twitter.android", "X", null),
            LinkHandlerApp("com.twitter.android", "X", null),
            LinkHandlerApp("com.reddit.frontpage", "Reddit", null, isDefault = true)
        )

        val result = filterLinkHandlers(candidates = candidates, excludedPackages = emptySet())

        assertEquals(
            listOf("com.reddit.frontpage", "com.instagram.android", "com.twitter.android"),
            result.map { it.packageName }
        )
    }
}
