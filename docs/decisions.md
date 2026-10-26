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
