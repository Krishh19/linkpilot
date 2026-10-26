package com.linkpilot.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class Mode {
    @SerialName("NORMAL")
    NORMAL,

    @SerialName("PRIVATE")
    PRIVATE
}

@Serializable
sealed interface Action {
    @Serializable
    @SerialName("OpenInBrowser")
    data class OpenInBrowser(
        val pkg: String,
        val mode: Mode = Mode.NORMAL
    ) : Action

    @Serializable
    @SerialName("OpenInApp")
    data class OpenInApp(
        val pkg: String
    ) : Action

    @Serializable
    @SerialName("AlwaysAsk")
    data object AlwaysAsk : Action
}

@Serializable
data class Match(
    val domains: List<String> = emptyList(),        // exact or wildcard (e.g. *.reddit.com), lowercase, punycode
    val urlRegex: String? = null,                   // guarded, optional
    val sourcePackages: List<String> = emptyList()  // empty = any source
)

@Serializable
data class Rule(
    val id: String,
    val name: String? = null,
    val enabled: Boolean = true,
    val priority: Int = 0,
    val match: Match,
    val action: Action,
    val createdAtEpochMs: Long = System.currentTimeMillis(),
    val hitCount: Int = 0
)

@Serializable
enum class CleanerLevel {
    @SerialName("OFF")
    OFF,

    @SerialName("STANDARD")
    STANDARD,

    @SerialName("AGGRESSIVE")
    AGGRESSIVE
}

@Serializable
enum class PickerReason {
    NO_RULE_MATCH,
    RULE_ACTION_ALWAYS_ASK,
    TARGET_NOT_INSTALLED,
    REJECTED_INPUT
}

@Serializable
sealed interface Decision {
    @Serializable
    @SerialName("Launch")
    data class Launch(
        val rule: Rule?,
        val action: Action
    ) : Decision

    @Serializable
    @SerialName("ShowPicker")
    data class ShowPicker(
        val reason: PickerReason
    ) : Decision
}

@Serializable
data class RoutingResult(
    val cleanedUrl: String,
    val originalUrl: String,
    val removedParams: List<String> = emptyList(),
    val sourcePackage: String? = null,
    val decision: Decision
)

@Serializable
data class Settings(
    val globalDefaultBrowser: String? = null,
    val cleanerLevel: CleanerLevel = CleanerLevel.STANDARD,
    val historyEnabled: Boolean = false,
    val historyRetentionDays: Int = 7,
    val schemaVersion: Int = 1
)

@Serializable
data class RedirectWrapper(
    val domain: String,
    val path: String? = null,
    val param: String
)

@Serializable
data class CleanerConfig(
    val version: Int = 1,
    val updatedAt: String = "",
    val globalTrackingParams: List<String> = emptyList(),
    val domainTrackingParams: Map<String, List<String>> = emptyMap(),
    val redirectWrappers: List<RedirectWrapper> = emptyList(),
    val safeExceptions: Map<String, List<String>> = emptyMap()
)
