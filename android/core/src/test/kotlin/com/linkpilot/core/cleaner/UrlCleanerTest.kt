package com.linkpilot.core.cleaner

import com.linkpilot.core.model.CleanerConfig
import com.linkpilot.core.model.CleanerLevel
import com.linkpilot.core.model.RedirectWrapper
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@Serializable
data class CleanerFixture(
    val input: String,
    val level: String,
    val expected: String,
    val removed: List<String>
)

class UrlCleanerTest {

    private lateinit var cleanerConfig: CleanerConfig
    private lateinit var cleaner: UrlCleaner

    @Before
    fun setUp() {
        cleanerConfig = CleanerConfig(
            version = 1,
            globalTrackingParams = listOf(
                "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
                "utm_id", "utm_source_platform", "utm_creative_format", "utm_marketing_tactic",
                "fbclid", "gclid", "gclsrc", "dclid", "wbraid", "gbraid", "msclkid",
                "igshid", "mc_eid", "mc_cid", "_hsenc", "_hsmi", "mkt_tok", "yclid",
                "_openstat", "s_kwcid", "zenid", "guccounter", "ncid"
            ),
            domainTrackingParams = mapOf(
                "twitter.com" to listOf("s", "t", "ref_src", "ref_url"),
                "x.com" to listOf("s", "t", "ref_src", "ref_url"),
                "youtube.com" to listOf("si", "feature", "pp"),
                "youtu.be" to listOf("si", "feature"),
                "spotify.com" to listOf("si", "context"),
                "open.spotify.com" to listOf("si", "context"),
                "instagram.com" to listOf("igsh", "utm_source"),
                "tiktok.com" to listOf("_r", "_t", "is_copy_url", "is_from_webapp", "sender_device"),
                "amazon.com" to listOf("tag", "ref_", "pf_rd_r", "pf_rd_m", "pf_rd_t", "pf_rd_i", "pf_rd_p", "pf_rd_s"),
                "aliexpress.com" to listOf("spm", "scm", "pvid", "algo_pvid", "algo_exp_id"),
                "reddit.com" to listOf("ref", "ref_source")
            ),
            redirectWrappers = listOf(
                RedirectWrapper("l.facebook.com", null, "u"),
                RedirectWrapper("lm.facebook.com", null, "u"),
                RedirectWrapper("out.reddit.com", null, "url"),
                RedirectWrapper("www.google.com", "/url", "q"),
                RedirectWrapper("google.com", "/url", "q"),
                RedirectWrapper("slack-redir.net", "/link", "url")
            ),
            safeExceptions = mapOf(
                "youtube.com" to listOf("t", "v", "list", "index"),
                "youtu.be" to listOf("t")
            )
        )
        cleaner = UrlCleaner(cleanerConfig)
    }

    @Test
    fun testAllFixturesFromResource() {
        val stream = javaClass.classLoader.getResourceAsStream("fixtures/url_cleaner_fixtures.json")
            ?: error("Fixture file url_cleaner_fixtures.json not found in resources!")

        val jsonString = stream.bufferedReader().use { it.readText() }
        val fixtures = Json { ignoreUnknownKeys = true }.decodeFromString<List<CleanerFixture>>(jsonString)

        assertTrue("Expected at least 150 fixtures, found ${fixtures.size}", fixtures.size >= 150)

        for ((index, fixture) in fixtures.withIndex()) {
            val level = CleanerLevel.valueOf(fixture.level)
            val result = cleaner.clean(fixture.input, level)

            assertEquals(
                "Fixture #$index failed on input: ${fixture.input}",
                fixture.expected,
                result.cleanedUrl
            )

            // Verify removed parameters count
            assertEquals(
                "Fixture #$index removed params mismatch for ${fixture.input}",
                fixture.removed.map { it.lowercase() }.sorted(),
                result.removedParams.map { it.lowercase() }.sorted()
            )
        }
    }

    @Test
    fun testRedirectUnwrappingLoopSafety() {
        // A redirects to B, B redirects back to A -> must not hang or infinite loop
        val circularConfig = cleanerConfig.copy(
            redirectWrappers = listOf(
                RedirectWrapper("a.com", null, "u"),
                RedirectWrapper("b.com", null, "u")
            )
        )
        val testCleaner = UrlCleaner(circularConfig)
        val url = "https://a.com/redir?u=" + java.net.URLEncoder.encode("https://b.com/redir?u=https%3A%2F%2Fa.com%2Fredir", "UTF-8")

        val result = testCleaner.clean(url)
        assertFalse(result.cleanedUrl.isEmpty())
    }

    @Test
    fun testRedirectUnwrappingHopLimit() {
        // Chain 5 redirects: hop limit is 3, so it should stop at hop 3
        val hopConfig = cleanerConfig.copy(
            redirectWrappers = listOf(
                RedirectWrapper("r.com", null, "target")
            )
        )
        val testCleaner = UrlCleaner(hopConfig)

        val hop4 = "https://r.com/step?target=" + java.net.URLEncoder.encode("https://final.org/destination", "UTF-8")
        val hop3 = "https://r.com/step?target=" + java.net.URLEncoder.encode(hop4, "UTF-8")
        val hop2 = "https://r.com/step?target=" + java.net.URLEncoder.encode(hop3, "UTF-8")
        val hop1 = "https://r.com/step?target=" + java.net.URLEncoder.encode(hop2, "UTF-8")

        val result = testCleaner.clean(hop1)
        // Should have unwrapped 3 times
        assertTrue(result.unwrapped)
        assertEquals("https://r.com/step?target=https://final.org/destination", result.cleanedUrl)
    }

    @Test
    fun testUnknownParametersArePreserved() {
        val input = "https://example.com/search?custom_engine=v2&foo=bar&utm_source=test"
        val result = cleaner.clean(input)
        assertEquals("https://example.com/search?custom_engine=v2&foo=bar", result.cleanedUrl)
        assertEquals(listOf("utm_source"), result.removedParams)
    }

    @Test
    fun testFragmentAndPortPreservation() {
        val input = "https://example.com:8443/view?item=42&utm_medium=cpc#reviews"
        val result = cleaner.clean(input)
        assertEquals("https://example.com:8443/view?item=42#reviews", result.cleanedUrl)
    }

    @Test
    fun testEmptyQueryParameters() {
        val input = "https://example.com/empty?"
        val result = cleaner.clean(input)
        assertEquals("https://example.com/empty", result.cleanedUrl)
    }

    @Test
    fun testPunycodeDomainCleaning() {
        val input = "https://xn--mnchen-3ya.de/portal?utm_campaign=city"
        val result = cleaner.clean(input)
        assertEquals("https://xn--mnchen-3ya.de/portal", result.cleanedUrl)
    }

    @Test
    fun testSafeExceptionsHonored() {
        val youtubeUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=120s&list=PL123&si=trackerToken"
        val result = cleaner.clean(youtubeUrl)
        assertEquals("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=120s&list=PL123", result.cleanedUrl)
        assertEquals(listOf("si"), result.removedParams)
    }
}
