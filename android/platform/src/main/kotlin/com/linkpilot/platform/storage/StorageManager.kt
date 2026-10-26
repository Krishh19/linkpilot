package com.linkpilot.platform.storage

import android.content.Context
import com.linkpilot.core.model.CleanerConfig
import com.linkpilot.core.model.Rule
import com.linkpilot.core.model.Settings
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import java.util.concurrent.atomic.AtomicReference

class StorageManager(private val context: Context) {

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        prettyPrint = true
    }

    private val rulesFile = File(context.filesDir, "rules.json")
    private val settingsFile = File(context.filesDir, "settings.json")
    private val usageCountersFile = File(context.filesDir, "usage_counters.json")

    // In-memory atomic cached snapshots for instant read
    private val cachedRules = AtomicReference<List<Rule>>(null)
    private val cachedSettings = AtomicReference<Settings>(null)
    private val cachedCleanerConfig = AtomicReference<CleanerConfig>(null)
    private val cachedUsageCounters = AtomicReference<Map<String, Int>>(null)

    fun getRules(): List<Rule> {
        val cached = cachedRules.get()
        if (cached != null) return cached

        val loaded = synchronized(rulesFile) {
            if (rulesFile.exists()) {
                try {
                    json.decodeFromString<List<Rule>>(rulesFile.readText())
                } catch (_: Exception) {
                    emptyList()
                }
            } else {
                emptyList()
            }
        }
        cachedRules.set(loaded)
        return loaded
    }

    fun saveRules(rules: List<Rule>) {
        synchronized(rulesFile) {
            val content = json.encodeToString(rules)
            writeAtomically(rulesFile, content)
            cachedRules.set(rules)
        }
    }

    fun getSettings(): Settings {
        val cached = cachedSettings.get()
        if (cached != null) return cached

        val loaded = synchronized(settingsFile) {
            if (settingsFile.exists()) {
                try {
                    json.decodeFromString<Settings>(settingsFile.readText())
                } catch (_: Exception) {
                    Settings()
                }
            } else {
                Settings()
            }
        }
        cachedSettings.set(loaded)
        return loaded
    }

    fun saveSettings(settings: Settings) {
        synchronized(settingsFile) {
            val content = json.encodeToString(settings)
            writeAtomically(settingsFile, content)
            cachedSettings.set(settings)
        }
    }

    fun getCleanerConfig(): CleanerConfig {
        val cached = cachedCleanerConfig.get()
        if (cached != null) return cached

        val loaded = try {
            context.assets.open("cleaner_rules.json").use { stream ->
                val text = stream.bufferedReader().readText()
                json.decodeFromString<CleanerConfig>(text)
            }
        } catch (_: Exception) {
            CleanerConfig()
        }
        cachedCleanerConfig.set(loaded)
        return loaded
    }

    fun getUsageCounters(): Map<String, Int> {
        val cached = cachedUsageCounters.get()
        if (cached != null) return cached

        val loaded = synchronized(usageCountersFile) {
            if (usageCountersFile.exists()) {
                try {
                    json.decodeFromString<Map<String, Int>>(usageCountersFile.readText())
                } catch (_: Exception) {
                    emptyMap()
                }
            } else {
                emptyMap()
            }
        }
        cachedUsageCounters.set(loaded)
        return loaded
    }

    fun incrementUsage(pkg: String) {
        synchronized(usageCountersFile) {
            val current = getUsageCounters().toMutableMap()
            current[pkg] = (current[pkg] ?: 0) + 1
            val content = json.encodeToString(current)
            writeAtomically(usageCountersFile, content)
            cachedUsageCounters.set(current)
        }
    }

    private fun writeAtomically(targetFile: File, content: String) {
        val tempFile = File(targetFile.parentFile, targetFile.name + ".tmp")
        tempFile.writeText(content)
        if (!tempFile.renameTo(targetFile)) {
            // Fallback for Windows or systems where renameTo over existing file fails
            targetFile.delete()
            tempFile.renameTo(targetFile)
        }
    }
}
