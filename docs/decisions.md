# Architectural Decision Records (ADRs)

## ADR-0001: Pure Native Routing Path
- **Status**: Accepted
- **Context**: PRD Section 6 requires routing links within < 150 ms (warm) and < 300 ms (cold). Flutter engine cold startup typically takes 400-800 ms on mid-range Android devices.
- **Decision**: The link intake (`RouterActivity`) and routing decision path are implemented 100% in pure Kotlin (`:core` and `:platform`), with zero dependency on the Flutter engine or Dart VM. The Flutter engine is solely launched for `MainActivity` (settings, rule management, history viewer, onboarding).
- **Consequences**: Fast link routing, low memory footprint on link taps, no Flutter initialization jank.

## ADR-0002: Zero Network / Telemetry Stance
- **Status**: Accepted
- **Context**: PRD Section 2 & 11 mandates absolute user privacy and offline operation.
- **Decision**: No `android.permission.INTERNET` in release builds. No analytics, tracking, or crashlytics SDKs. All rules, cleaner definitions, and history stay strictly on device.
- **Consequences**: High user trust, offline resilience, zero third-party data leaks.

## ADR-0003: Core Engine Separation (`:core`)
- **Status**: Accepted
- **Context**: Matching, regex bounds, URL cleaning, and redirect unwrapping must be testable without Android framework mocks, and must be the single source of truth for both the background router and Flutter testing UI.
- **Decision**: `:core` is a pure Kotlin/JVM module with no `android.*` imports. It can run in standard JVM tests with 100% determinism.
- **Consequences**: Blazing fast unit tests, clean separation of concerns, single source of truth.

## ADR-0004: BrowserAdapter Empirical Table & Zero Fabricated Extras
- **Status**: Accepted
- **Context**: PRD Section 7 (FR-D3), Section 17 (Rule 7). Various browsers handle incognito/private modes differently via intent extras (`private_browsing_mode`, `EXTRA_OPEN_NEW_INCOGNITO_TAB`, or inherent architecture). Some browsers (Opera, Samsung Internet) do not expose public third-party private tab intent extras.
- **Decision**: All browser quirks and private mode extras are isolated strictly within `BrowserAdapterTable` in `:platform`. No intent extras are invented or assumed without verification. Unsupported browsers gracefully fall back to normal mode with clear capability badges in the UI.
- **Consequences**: Deterministic launcher behavior, honest capability representation in UI, zero crashes from unsupported browser intent actions.

## ADR-0005: Automated Privacy & Manifest Audit
- **Status**: Accepted
- **Context**: PRD Section 11 & Section 17 (Rule 3). The release APK must guarantee zero `INTERNET` and zero `QUERY_ALL_PACKAGES` permissions, and no URL logging across all build types.
- **Decision**: Implemented `PrivacyAndManifestAuditTest` in `:app` executing as part of the Gradle verification suite. R8 Proguard rules strictly preserve model serialization while shrinking and obfuscating code.
- **Consequences**: Continuous regression protection preventing accidental addition of network or package visibility permissions.

## ADR-0006: User-Initiated Clipboard Tile & Shortcuts
- **Status**: Accepted
- **Context**: PRD FR-G2. Quick Settings tile and app launcher shortcut "Open copied link" must read clipboard only on explicit user tap. Background clipboard access violates Android 10+ privacy policies.
- **Decision**: `LinkPilotTileService.onClick()` and `RouterActivity` with action `com.linkpilot.OPEN_COPIED_LINK` access `ClipboardManager` only synchronously upon user invocation. No background listeners or services exist.
- **Consequences**: Compliance with modern Android privacy requirements, clean user UX for bypassing trapped in-app WebViews.
