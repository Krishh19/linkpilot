package com.linkpilot.platform.storage

import android.content.Context
import com.linkpilot.core.model.CleanerConfig
import com.linkpilot.core.model.Rule
import com.linkpilot.core.model.Settings
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import java.util.UUID
import java.util.concurrent.atomic.AtomicReference

@Serializable
data class HistoryEntry(
    val id: String,
    val url: String,
    val targetPackage: String,
    val timestampEpochMs: Long
)

@Serializable
data class BackupPayload(
    val schemaVersion: Int = 1,
    val exportedAtEpochMs: Long,
    val rules: List<Rule>,
    val settings: Settings,
    val usageCounters: Map<String, Int>
)

class StorageManager private constructor(context: Context) {

    companion object {
        @Volatile
        private var instance: StorageManager? = null

        fun get(context: Context): StorageManager {
            return instance ?: synchronized(this) {
                instance ?: StorageManager(context.applicationContext).also { instance = it }
            }
        }
    }

    private val context: Context = context.applicationContext

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        prettyPrint = true
    }

    private val rulesFile = File(context.filesDir, "rules.json")
    private val settingsFile = File(context.filesDir, "settings.json")
    private val usageCountersFile = File(context.filesDir, "usage_counters.json")
    private val historyFile = File(context.filesDir, "history.json")
    private val appPrefs = context.getSharedPreferences("linkpilot_app", Context.MODE_PRIVATE)

    // In-memory atomic cached snapshots for instant read
    private val cachedRules = AtomicReference<List<Rule>>(null)
    private val cachedSettings = AtomicReference<Settings>(null)
    private val cachedCleanerConfig = AtomicReference<CleanerConfig>(null)
    private val cachedUsageCounters = AtomicReference<Map<String, Int>>(null)
    private val cachedHistory = AtomicReference<List<HistoryEntry>>(null)

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

        val assetPaths = listOf(
            "flutter_assets/assets/cleaner_rules.json",
            "cleaner_rules.json"
        )
        val loaded = assetPaths.firstNotNullOfOrNull { path ->
            try {
                context.assets.open(path).use { stream ->
                    json.decodeFromString<CleanerConfig>(stream.bufferedReader().readText())
                }
            } catch (_: Exception) {
                null
            }
        } ?: CleanerConfig()
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

    // --- History & Auto-Purge (FR-H) ---

    fun getHistory(): List<HistoryEntry> {
        val cached = cachedHistory.get()
        if (cached != null) return cached

        val loaded = synchronized(historyFile) {
            if (historyFile.exists()) {
                try {
                    val entries = json.decodeFromString<List<HistoryEntry>>(historyFile.readText())
                    val settings = getSettings()
                    purgeOldHistory(entries, settings.historyRetentionDays)
                } catch (_: Exception) {
                    emptyList()
                }
            } else {
                emptyList()
            }
        }
        cachedHistory.set(loaded)
        return loaded
    }

    fun addHistoryItem(url: String, targetPackage: String) {
        val settings = getSettings()
        if (!settings.historyEnabled) return

        synchronized(historyFile) {
            val now = System.currentTimeMillis()
            val newEntry = HistoryEntry(
                id = UUID.randomUUID().toString(),
                url = url,
                targetPackage = targetPackage,
                timestampEpochMs = now
            )
            val current = getHistory()
            val updated = purgeOldHistory(listOf(newEntry) + current, settings.historyRetentionDays)
            val content = json.encodeToString(updated)
            writeAtomically(historyFile, content)
            cachedHistory.set(updated)
        }
    }

    fun clearHistory(): Boolean {
        synchronized(historyFile) {
            if (historyFile.exists()) {
                historyFile.delete()
            }
            cachedHistory.set(emptyList())
            return true
        }
    }

    fun deleteHistoryItem(id: String): Boolean {
        synchronized(historyFile) {
            val current = getHistory().filterNot { it.id == id }
            val content = json.encodeToString(current)
            writeAtomically(historyFile, content)
            cachedHistory.set(current)
            return true
        }
    }

    private fun purgeOldHistory(entries: List<HistoryEntry>, retentionDays: Int): List<HistoryEntry> {
        val cutoff = System.currentTimeMillis() - (retentionDays.coerceAtLeast(1) * 86_400_000L)
        return entries.filter { it.timestampEpochMs >= cutoff }
    }

    // --- First-run setup ---

    fun isOnboardingCompleted(): Boolean {
        return appPrefs.getBoolean("onboarding_completed", false)
    }

    fun setOnboardingCompleted(completed: Boolean): Boolean {
        appPrefs.edit().putBoolean("onboarding_completed", completed).apply()
        return true
    }

    // --- Backup & Restore (FR-I) ---

    fun exportBackupJson(): String {
        val payload = BackupPayload(
            schemaVersion = 1,
            exportedAtEpochMs = System.currentTimeMillis(),
            rules = getRules(),
            settings = getSettings(),
            usageCounters = getUsageCounters()
        )
        return json.encodeToString(payload)
    }

    fun importBackupJson(jsonString: String, merge: Boolean): Pair<Int, Boolean> {
        return try {
            val payload = json.decodeFromString<BackupPayload>(jsonString)
            if (payload.schemaVersion > 1) {
                // Unsupported newer schema version
                return Pair(0, false)
            }

            if (merge) {
                val existingRules = getRules()
                val existingIds = existingRules.map { it.id }.toSet()
                val newRules = payload.rules.filterNot { it.id in existingIds }
                val merged = existingRules + newRules
                saveRules(merged)
                Pair(merged.size, true)
            } else {
                saveRules(payload.rules)
                saveSettings(payload.settings)
                Pair(payload.rules.size, true)
            }
        } catch (_: Exception) {
            Pair(0, false)
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
