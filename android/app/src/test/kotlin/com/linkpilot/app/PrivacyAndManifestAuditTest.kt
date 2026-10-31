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
    fun testCustomTabsProviderServiceDeclared() {
        val content = getManifestContent()
        assertTrue(
            "LinkPilot must advertise a Custom Tabs service so in-app Custom Tabs (e.g. Reddit) bind to it",
            content.contains(".LinkPilotCustomTabsService")
        )
        assertTrue(
            "Custom Tabs service must declare the system bind action",
            content.contains("android.support.customtabs.action.CustomTabsService")
        )
    }

    @Test
    fun testRouterActivityHandlesBothWebSchemes() {
        val content = getManifestContent()
        assertTrue(
            "RouterActivity must handle http links to qualify for ROLE_BROWSER",
            content.contains("android:scheme=\"http\"")
        )
        assertTrue(
            "RouterActivity must handle https links to qualify for ROLE_BROWSER",
            content.contains("android:scheme=\"https\"")
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
