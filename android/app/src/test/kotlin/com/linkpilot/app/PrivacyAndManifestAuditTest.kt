package com.linkpilot.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class PrivacyAndManifestAuditTest {

    private fun getManifestContent(): String {
        val candidates = listOf(
            File("src/main/AndroidManifest.xml"),
            File("app/src/main/AndroidManifest.xml"),
            File("android/app/src/main/AndroidManifest.xml")
        )
        val file = candidates.firstOrNull { it.exists() }
        assertTrue("AndroidManifest.xml should exist in candidate paths", file != null)
        return file!!.readText()
    }

    @Test
    fun testNoInternetPermissionInManifest() {
        val content = getManifestContent()
        assertFalse(
            "CRITICAL VIOLATION: INTERNET permission found in AndroidManifest.xml",
            content.contains("android.permission.INTERNET")
        )
    }

    @Test
    fun testNoQueryAllPackagesPermissionInManifest() {
        val content = getManifestContent()
        assertFalse(
            "CRITICAL VIOLATION: QUERY_ALL_PACKAGES permission found in AndroidManifest.xml",
            content.contains("android.permission.QUERY_ALL_PACKAGES")
        )
    }

    @Test
    fun testRouterActivityTranslucentAndExported() {
        val content = getManifestContent()
        assertTrue(
            "RouterActivity must be exported to intercept VIEW intents",
            content.contains("android:name=\".RouterActivity\"") && content.contains("android:exported=\"true\"")
        )
        assertTrue(
            "RouterActivity must use translucent theme for zero visible flicker",
            content.contains("Theme.LinkPilot.Translucent")
        )
    }
}
