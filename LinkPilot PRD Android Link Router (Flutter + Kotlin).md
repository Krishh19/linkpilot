# LinkPilot: Product Requirements Document

*Working title. Android-first link router built with Flutter and native Kotlin. Version 1.0 draft, 26 October 2026.*

> **Implementation status (1 November 2026).** LinkPilot is open source and every feature is free. The Pro tier, purchase gating, and five-rule free-tier limit described in this draft were removed. References to billing, pricing, and a paid tier in sections 6, 9, 14, 15, and 16 are retained only as design history and no longer describe the product.

## 1. Overview

**One-liner.** LinkPilot is a default-browser app that never shows a web page. Every link tapped anywhere on the phone passes through it, is cleaned of trackers, and is opened in the browser (and mode) the user chose, either by a saved rule or a one-tap picker.

**Problem.** People use several browsers (work vs personal, private vs fast). Android lets only one be the default, and apps like Reddit, X and Instagram often open links in their own in-app browser. Links land in the wrong place, carry tracking junk, and users end up copying and pasting URLs by hand.

**Vision.** Fast, private, rule-based routing. If a rule matches, the right browser opens in under 150 ms. If not, a bottom-sheet picker appears instantly. No accounts, no cloud, no analytics.

**How to use this document.** It is written for an AI coding IDE or agent plus the human reviewing it. Sections 5 to 9 and 16 to 17 are the build contract. Where something is unverified (browser-specific behavior), the requirement is to build a test harness and a capability table, not to assume.

## 2. Goals, non-goals, success metrics

**Goals**

- G1. Become the system default browser and receive every http/https link.
- G2. Route links by rules: domain, URL pattern, and source app.
- G3. Open links in a chosen browser, and in private mode where that browser allows it.
- G4. Strip known tracking parameters and unwrap redirect wrappers before opening.
- G5. Provide a fast quick picker sorted by usage.
- G6. Be provably private: no analytics, no link logging by default, ideally no INTERNET permission.

**Non-goals (v1)**

- Building a browser or rendering web pages.
- iOS (see section 4), desktop, and web.
- Intercepting hard-coded in-app WebViews (technically impossible without invasive Accessibility Services, which we will not use).
- Targeting Chrome or Edge profiles on Android (no supported intent API).
- Cloud sync and accounts.

**Success metrics**

| Metric | Target |
| --- | --- |
| Rule-matched link to target browser visible | p95 under 150 ms on a mid-range device (warm process), under 300 ms cold |
| Picker visible after link tap | p95 under 300 ms |
| Crash-free sessions | 99.8% or better |
| Users who create at least one rule within 7 days | 40% or more (measured only via opt-in feedback or Play vitals, never in-app analytics) |
| Play rating | 4.5 or higher |

## 3. Users and key stories

- **Multi-browser power user.** Wants Reddit links in Firefox and work links in Chrome without thinking.
- **Privacy-minded user.** Wants trackers stripped and certain sites always in a private tab.
- **Casual user.** Just wants a choice popup instead of the wrong browser opening.

Stories:

1. As a user, I set LinkPilot as default browser in under 60 seconds from first launch.
2. As a user, I tap a link in any app and it opens in my chosen browser without a visible flicker.
3. As a user, I tap Always for this site in the picker and never see the picker for that site again.
4. As a user, I create a rule so links coming from Reddit open in Firefox.
5. As a user, I see what was cleaned (for example, removed 3 trackers) and can open the original URL instead.
6. As a user, I share a link from a trapped in-app browser to LinkPilot and pick a browser.
7. As a user, I back up and restore my rules as a file.

## 4. Platform scope and hard constraints

**Android first (API 26+).** Android lets an app hold the browser role, receive all web links, and read an approximate source app through `Activity.getReferrer()`.

**iOS is deferred.** iOS only gives the default-browser role to qualifying browsers with a special Apple entitlement, never reveals the source app, and cannot override in-app browsers. A later iOS version would be a share-extension that forwards links to other browsers by URL scheme.

**What can be intercepted on Android**

| Source behavior | Interceptable? |
| --- | --- |
| App fires a normal ACTION\_VIEW intent, or a Custom Tab with no pinned package | Yes, routed to us as default browser |
| Link verified to a native app (Android App Links, for example youtube.com) | No by default: the system opens that app and we never see the link. We can offer an Open in app action only for links that reach us. |
| Custom Tab pinned to Chrome | Often no |
| Hard-coded WebView (Instagram, Facebook and similar) | No. Mitigate with share target, clipboard tile, and an onboarding guide to each app’s Open links externally setting |

The product must be honest about these limits in onboarding and in a Help screen.

## 5. Technology stack

Versions below were checked on 26 October 2026. Rule: use the latest stable at project start, and take the newest patch release.

| Area | Choice | Notes |
| --- | --- | --- |
| UI framework | **Flutter 3.47.x stable** (3.47.1 released 19 Aug 2026) with **Dart 3.13.x** | Flutter 3.50 is slated for November 2026. Upgrade after its first patch release, not before. |
| Native language | **Kotlin 2.4.x** (K2 compiler) | Use KSP, not kapt, for annotation processing. |
| Android SDK | minSdk 26, compileSdk 36 (move to 37 when the toolchain allows), **targetSdk 36 minimum** | Android 17 (API 37) shipped 16 June 2026. Google Play requires new apps and updates to target API 36 or higher from 31 Aug 2026, and Android 17 becomes the required target around August 2027. Plan the API 37 bump before then. |
| Build | Gradle with Kotlin DSL and a version catalog (`libs.versions.toml`) | Do not hand-pin AGP, Gradle or Kotlin below what Flutter’s tooling accepts. Let `flutter create` templates set the AGP and Gradle baseline, then upgrade through supported paths. |
| Native UI (picker only) | Jetpack Compose with Material 3 (current stable BOM) | Used only inside the router activity. Ship a Baseline Profile. |
| Async | Kotlin coroutines and Flow |  |
| Rules and settings storage | JSON file via kotlinx.serialization, loaded into memory, written atomically | Rule counts are small, so a file gives the fastest cold read. |
| History and stats storage | Room (KSP) | Opt-in feature, see FR-H. |
| Flutter-native bridge | **Pigeon** (latest) generating Kotlin and Dart | Pigeon data classes are the Dart models, so no freezed is needed. |
| Flutter state | flutter\_riverpod 3.x |  |
| Flutter navigation | go\_router |  |
| Flutter theming | Material 3, dynamic color, adaptive layouts | Android 17 makes adaptive large-screen UI mandatory for apps targeting API 37, so build responsive layouts from day one. |
| Localization | `flutter gen-l10n`, English plus extensible ARB files |  |
| Billing | None. LinkPilot is free and open source, so no in-app purchase library is included. |
| Quality | flutter\_lints or very\_good\_analysis, ktlint, detekt, mocktail, Robolectric, AndroidX Test, Macrobenchmark |  |
| CI | GitHub Actions |  |

## 6. Architecture

**Core principle.** The link path must not start the Flutter engine. Flutter is only the settings app. Routing is pure native Kotlin so it feels instant.

```
Link tapped in any app
   |
   v
RouterActivity (native, translucent, exported, browser intent filter)
   |-- parse + validate URL
   |-- detect source app (getReferrer, may be null)
   |-- unwrap redirects, strip trackers      (:core)
   |-- evaluate rules                        (:core)
   |        |                     |
   |   rule matched          no match / ask
   |        |                     |
   |   launch browser        show Compose bottom-sheet picker
   |        |                     |
   +--- finish() <----------------+

MainActivity (Flutter) = launcher icon: onboarding, rules editor, browsers, history, backup, settings
        ^ Pigeon API v
Native platform layer (storage, discovery, launching) shared by both activities
```

**Modules and repo layout**

```
linkpilot/
  AGENTS.md                      agent rules, see section 17
  pubspec.yaml
  lib/
    main.dart
    app/                         router, theme, shell
    features/                    onboarding, rules, browsers, history, backup, pro, help
    data/                        thin repositories over the Pigeon API
    generated/                   Pigeon output, do not edit
  pigeons/linkpilot_api.dart
  assets/cleaner_rules.json      bundled tracker and redirect rules, versioned
  android/
    app/                         host app: manifest, MainActivity, RouterActivity
    core/                        pure Kotlin/JVM: models, matcher, cleaner, unwrapper (no Android imports)
    platform/                    Android library: storage, browser discovery, launcher, picker UI, Pigeon impl
  tools/adb_scenarios.sh         link-injection scenarios for manual and CI checks
  docs/browser-capabilities.md   verified per-browser behavior, see FR-D
```

**Key decisions**

- **One matching engine.** The rules engine and URL cleaner live only in `:core` (Kotlin). Dart never reimplements matching. The Flutter Test URL screen calls the native engine through Pigeon, so what users see is exactly what the router does.
- **In-memory snapshot.** On process start the router reads the rules file once. A change from Flutter writes the file atomically and tells the running router to reload.
- **No heavy Application init.** Do not initialize Flutter, Room, or Billing in the Application class.
- **Single APK, one process.** Both activities share the app process, and Flutter engine creation happens only when MainActivity launches.

## 7. Functional requirements

Priorities: P0 = MVP, P1 = v1, P2 = later. AC = acceptance criteria.

### FR-A. Default browser and onboarding

- **A1 \[P0\]** The manifest qualifies the app as a browser (see section 12) and the app requests the browser role via `RoleManager.createRequestRoleIntent(ROLE_BROWSER)` on API 29+, with a fallback to the default-apps settings screen below that. AC: after onboarding, `adb shell cmd role get-role-holders android.app.role.BROWSER` lists our package.
- **A2 \[P0\]** Onboarding is at most 4 screens: what it does, set as default, pick a default browser, enable optional extras. AC: a new user reaches a working state in under 60 seconds.
- **A3 \[P0\]** The home screen shows a live status: default browser role held or not, number of installed browsers found, router test button.
- **A4 \[P1\]** A Help screen explains per app how to turn on Open links externally (Reddit, X, Instagram, Facebook, LinkedIn, Telegram) and states the in-app browser limits from section 4.

### FR-B. Link intake and routing

- **B1 \[P0\]** RouterActivity accepts ACTION\_VIEW with http and https data only. Any other scheme or malformed URL is rejected and the activity finishes with no action.
- **B2 \[P0\]** Never loop: launched browser intents always set an explicit target package that is not ours.
- **B3 \[P0\]** Source detection uses `getReferrer()` and exposes `sourcePackage: String?`. Null is valid, and rules that require a source simply do not match.
- **B4 \[P0\]** If a launch fails (browser uninstalled or disabled), show the picker with an inline notice, and never drop the link.
- **B5 \[P1\]** A Open original (uncleaned) action is available in the picker.

### FR-C. Rules engine

- **C1 \[P0\]** Conditions: exact domain, wildcard domain (`*.reddit.com` matches subdomains and the apex), URL regex, source app package. A rule may combine domain and source conditions with AND.
- **C2 \[P0\]** Actions: OPEN\_IN\_BROWSER (package, mode), OPEN\_IN\_APP (package, for example a native app that is installed), ALWAYS\_ASK.
- **C3 \[P0\]** Resolution order: highest numeric priority wins. Ties break by specificity: URL regex, then exact domain, then wildcard domain, then source-only. Then the global default browser, then the picker.
- **C4 \[P0\]** Rules can be created from the picker (Always for this site, Always from this app) and from the Flutter editor. A rule is enabled by default and can be paused.
- **C5 \[P1\]** Smart suggestion: after the same browser is chosen 3 times for a domain, offer to save a rule. Counters are stored locally and can be disabled.
- **C6 \[P1\]** Rule import and export as JSON, see FR-I.
- **AC (engine).** `:core` has at least 60 unit tests covering precedence, wildcard edge cases (apex vs subdomain, lookalike domains such as notreddit.com), IDN and punycode hosts, ports, and regex timeouts. Regexes run with a time and length guard.

### FR-D. Browser discovery and capabilities

- **D1 \[P0\]** Discover installed browsers with `PackageManager.queryIntentActivities` on a sample https VIEW intent, using a `<queries>` declaration. Do not use QUERY\_ALL\_PACKAGES. Exclude our own package.
- **D2 \[P0\]** The user can hide or reorder browsers and set a global default.
- **D3 \[P1\]** Private-mode routing uses a **BrowserAdapter** table: for each known browser package, a capability flag (VERIFIED, BEST\_EFFORT, UNSUPPORTED) and the intent extras or alternate component needed. Seed it with Firefox-family browsers, Brave, DuckDuckGo, Opera, Vivaldi, Edge and Chrome, but treat every entry as unverified until tested on a real device. Document results in `docs/browser-capabilities.md`.
- **D4 \[P1\]** The UI shows a capability badge per browser (for example, Private tab: works, best effort, not supported) and falls back to normal mode with a one-time notice when private mode is unsupported.
- **D5 \[P0 by design\]** Browser profile targeting is out of scope on Android. Do not promise it in the UI or the store listing.

### FR-E. URL cleaner

- **E1 \[P0\]** Remove known tracking parameters from a bundled, versioned rule file `assets/cleaner_rules.json`: global params (`utm_*`, `fbclid`, `gclid`, `igshid`, `mc_eid`, and similar), plus per-domain params (for example share-tracking params on X, YouTube, Spotify). Unknown parameters are never removed.
- **E2 \[P0\]** Unwrap redirect wrappers that carry the destination in a query parameter (for example Facebook link shim, Google redirect URLs, Reddit outbound links). Wrappers that need a network call (shortened URLs) are not expanded offline.
- **E3 \[P0\]** Per-domain exceptions: some sites need certain parameters (such as video timestamps). Ship safe defaults and let users add exceptions.
- **E4 \[P1\]** Optional rewrites (off by default): AMP unwrapping, alternate frontends, old.reddit.com.
- **E5 \[P1\]** If you reuse an open-source list such as ClearURLs, verify its license and attribute it. If the license is incompatible, curate our own list.
- **AC.** A fixture file of at least 150 real-world URLs with expected output passes in `:core` tests, including cases where nothing should change.

### FR-F. Quick picker

- **F1 \[P0\]** A translucent bottom sheet shows installed browsers by icon and name, sorted by usage frequency, with the cleaned URL and a one-line summary of what was cleaned.
- **F2 \[P0\]** Buttons: Just once, Always for this site, Always from this app (hidden if the source is unknown).
- **F3 \[P1\]** Long-press a browser for open in private (when supported). Also copy link, share link, and show QR.
- **F4 \[P0\]** Accessible: TalkBack labels, 48dp touch targets, works in dark mode and with font scaling.
- **F5 \[P0\]** Dismissing the sheet (back or tap outside) finishes the activity without opening anything.

### FR-G. Share target and clipboard

- **G1 \[P1\]** Register for ACTION\_SEND with text/plain. Extract the first http(s) URL from the text and run the normal flow.
- **G2 \[P1\]** A Quick Settings tile and a launcher shortcut named Open copied link read the clipboard on user tap only. Never read the clipboard in the background.

### FR-H. History and statistics (opt-in)

- **H1 \[P1\]** Off by default. When enabled, store the last N links (user selects 24 hours, 7 days, or 30 days retention) in Room, with an auto-purge worker and a Clear all button.
- **H2 \[P1\]** Reopen in another browser from a history item.
- **H3 \[P0\]** Usage counts used for picker ordering are stored as per-browser counters only, never URLs.

### FR-I. Backup and restore

- **I1 \[P1\]** Export rules, exceptions, browser order and settings as a versioned JSON file through the system file picker (Storage Access Framework). No storage permission is requested.
- **I2 \[P1\]** Import validates the schema version, shows a preview (X rules, Y exceptions), and offers merge or replace.

### FR-J. Settings and features

- **J1 \[P0\]** Settings: default browser, cleaner level (Off, Standard, Aggressive), theme, history, haptics.
- **J2 \[P1\]** Every feature is available to every user: unlimited rules, source-app rules, private-mode routing, backup, and themes. No account, purchase, or network connection is required.
- **J3 \[P1\]** All state is stored locally, and the app works fully offline.

## 8. Data models

These live in `:core` and are exposed to Flutter through Pigeon.

```kotlin
data class Rule(
  val id: String,
  val name: String?,
  val enabled: Boolean,
  val priority: Int,
  val match: Match,
  val action: Action,
  val createdAtEpochMs: Long,
  val hitCount: Int,
)

data class Match(
  val domains: List<String>,        // exact or wildcard, lowercase, punycode
  val urlRegex: String?,            // guarded, optional
  val sourcePackages: List<String>, // empty = any source
)

sealed interface Action {
  data class OpenInBrowser(val pkg: String, val mode: Mode) : Action
  data class OpenInApp(val pkg: String) : Action
  object AlwaysAsk : Action
}

enum class Mode { NORMAL, PRIVATE }

data class RoutingResult(
  val cleanedUrl: String,
  val originalUrl: String,
  val removedParams: List<String>,
  val sourcePackage: String?,
  val decision: Decision,           // Launch(rule, action) | ShowPicker(reason)
)

data class Settings(
  val globalDefaultBrowser: String?,
  val cleanerLevel: CleanerLevel,
  val historyEnabled: Boolean,
  val historyRetentionDays: Int,
  val schemaVersion: Int,
)
```

The rules file stores `schemaVersion` and has explicit migrations. Unknown future fields must be preserved or ignored without crashing.

## 9. Router flow (reference behavior)

1. Receive intent. Reject anything that is not http or https, or longer than 8,192 characters.
2. Read the referrer to get `sourcePackage` (nullable).
3. Unwrap redirect wrappers (up to 3 hops, loop-safe), then strip trackers according to the cleaner level and exceptions.
4. Evaluate rules against the cleaned URL and the source package.
5. If a rule matches with a browser or app action, resolve the package. If it is missing or fails, go to step 6.
6. Otherwise show the picker. On a choice, launch with `Intent.ACTION_VIEW`, the cleaned URI, and an explicit package. Apply private-mode extras only if the BrowserAdapter says the browser supports them.
7. Increment local counters, optionally write history, and call `finish()` with no transition animation.

## 10. Flutter app: screens

- **Home**: default-browser status, router test, quick links to Rules and Browsers.
- **Onboarding**: 4 steps as in FR-A2.
- **Rules**: list with search, pause toggle, drag to set priority. Editor with domain chips, optional URL regex, source-app chooser (installed apps list), action selector, and a live Test URL panel (calls the native engine and shows the winning rule and cleaned URL).
- **Browsers**: installed browsers, order, hide, capability badges, set global default.
- **Cleaner**: level, exceptions, optional rewrites, last-updated date of bundled rules.
- **History** (if enabled): list, reopen in another browser, clear.
- **Backup**: export and import.
- **Help**: in-app browser guide and limits.
- **Settings** and **About/Privacy**: preferences, privacy statement, open-source licenses.

Use adaptive layouts (navigation rail on wide screens, bottom navigation on phones), Material 3 dynamic color, and support light and dark.

## 11. Non-functional requirements

- **Performance.** Warm rule-matched route p95 under 150 ms, cold under 300 ms. RouterActivity must not touch Flutter, Room, or Billing on the rule-matched path. Measure with Macrobenchmark on a mid-range reference device and fail CI on regression of more than 20%.
- **Privacy.** No analytics SDKs, no ad SDKs, no crash-reporting SDK that sends data automatically. URLs are never logged (not even in debug builds shipped to users). Target: no INTERNET permission in the release build, enforced by a CI manifest check.
- **Security.** The exported router treats all intent data and extras as untrusted. No `Intent.parseUri` on user data. Do not grant URI permissions. Regexes are length and time bounded. Rules import is schema validated. Backups contain no URLs from history.
- **Reliability.** If the rules file is corrupt, fall back to defaults and keep a single backup copy. The router must never crash on malformed input.
- **Accessibility.** TalkBack support, 48dp targets, contrast AA, font scaling to 200%, no color-only meaning.
- **Compatibility.** Android 8.0 (API 26) and up. Test on Android 12, 14, 16 and 17, plus one Samsung One UI device and one Pixel.
- **Size.** Release app download under 20 MB. Use R8, resource shrinking, and Play app bundles.
- **Localization.** All strings externalized from the first commit.

## 12. Android manifest and permissions

- **RouterActivity**: exported, translucent theme, `launchMode` singleInstance or singleTask with `excludeFromRecents`, taskAffinity empty. Intent filter: action VIEW, categories DEFAULT and BROWSABLE, data schemes http and https (no host). A second filter for ACTION\_SEND with mime type text/plain. Do not add the app-link auto-verify attribute.
- **MainActivity**: Flutter launcher activity, standard MAIN and LAUNCHER filter.
- **Permissions**: none required for the core flow. Explicitly avoid QUERY\_ALL\_PACKAGES and INTERNET. No purchase or billing library is included.
- **`<queries>`**: an intent query for VIEW with https scheme (browser discovery) and one for an installed-app lookup limited to the apps needed for source-app rules (the source app list should come from a user-driven picker rather than broad package visibility).
- **Quick Settings tile** service for Open copied link.
- Verify the app qualifies for the browser role on Android 17 devices.

## 13. Testing and QA

- **Unit (`:core`).** Matcher precedence, wildcard rules, cleaner fixtures (150+ URLs), unwrapper loops, regex guards, schema migrations.
- **Android instrumented.** RouterActivity receives synthetic intents and launches the expected explicit intent (use test doubles for the launcher). Verify malformed, non-http and oversized inputs finish cleanly.
- **Flutter.** Widget tests for the rules editor and onboarding, with a mocked Pigeon API. Integration tests for create-rule then test-URL.
- **Performance.** Macrobenchmark startup test for RouterActivity (rule matched and picker paths), Baseline Profile generation.
- **Compatibility harness.** `tools/adb_scenarios.sh` fires a fixed list of URLs and source apps at the router. Results feed `docs/browser-capabilities.md`. Private-tab behavior is tested by hand per browser, per browser version, and recorded with the date.
- **Release checks.** Pre-launch report clean, no new lint errors, manifest permission allow-list test passes.

## 14. CI/CD and release

- **PR pipeline.** `flutter analyze`, `flutter test`, `./gradlew :core:test :platform:testDebugUnitTest detekt ktlintCheck lint`, build debug APK, manifest permission check.
- **Release pipeline.** Signed AAB via Gradle with secrets from CI, mapping file upload, internal testing track.
- **Play Store.** Accurate listing that states the limits (cannot override hard-coded in-app browsers). Data safety form: no data collected. Prepare a short privacy policy. New personal developer accounts may need a closed testing period before production, so schedule for it.
- **Distribution.** Play Store first, optionally GitHub releases or F-Droid later.

## 15. Monetization

LinkPilot is free and open source. There is no Pro tier, purchase, subscription, account, advertising, or paid edition, and no feature is gated. Development is funded by contributors.

## 16. Milestones and AI-agent build plan

Each milestone has a gate. Do not start the next milestone until the gate passes.

| # | Milestone | Deliverables | Gate |
| --- | --- | --- | --- |
| M0 | Scaffold | `flutter create` with Kotlin, repo layout from section 6, version catalog, lint, CI skeleton, AGENTS.md | CI green on empty app; `flutter doctor` clean |
| M1 | Core engine | `:core` models, matcher, cleaner, unwrapper, 60+ unit tests, 150+ URL fixtures | `./gradlew :core:test` green |
| M2 | Router MVP | RouterActivity, manifest, browser discovery, launcher, explicit-package launch, picker UI, usage counters | Default role works on a real device; adb scenarios pass; rule-matched route under 150 ms warm |
| M3 | Flutter shell | Pigeon API, onboarding, home status, browsers screen, rules list and editor, Test URL panel | Rule created in Flutter changes router behavior with no app restart |
| M4 | Source-app rules and share | Referrer detection, source-app rules, share target, Open copied link tile, Help screen | All FR-B and FR-C and FR-G acceptance criteria met |
| M5 | Private mode and capability table | BrowserAdapter, per-browser device testing, capability badges, docs | `docs/browser-capabilities.md` filled from real tests |
| M6 | Backup and history | Backup and restore, opt-in history with purge | Restore on a clean install reproduces behavior exactly |
| M7 | Hardening and launch | Macrobenchmark, Baseline Profile, accessibility pass, privacy and manifest checks, Play listing assets | Closed test clean; vitals within targets |

**Suggested prompting order for the AI IDE:** (1) scaffold and rules for the repo, (2) `:core` with tests first, (3) native router and picker, (4) Pigeon contract, (5) Flutter screens one feature at a time, (6) browser adapters with a device test checklist, (7) release hardening. Ask the agent to state which acceptance criteria each change satisfies.

## 17. Rules for the AI coding agent (AGENTS.md content)

1. Routing and rule logic exist only in `:core`. Never duplicate matching or cleaning logic in Dart.
2. Never start the Flutter engine or initialize Room, Billing, or analytics-like code on the router path.
3. Never add network libraries, analytics, ad, or crash-reporting SDKs. Never add INTERNET or QUERY\_ALL\_PACKAGES permissions without an explicit written decision recorded in `docs/decisions.md`.
4. Never log URLs, titles, or source apps, in any build type.
5. Write tests with the code. A feature is not done until its acceptance criteria have tests, or a documented manual check where a device is required.
6. Prefer the latest stable versions at project start, use the newest patch release, and pin them in the version catalog and `pubspec.lock`. Do not downgrade tooling to silence a build error without recording why.
7. Treat browser-specific behavior (private tabs, extras) as unverified until a device test is recorded. Do not invent intent extras. Put every browser quirk in the BrowserAdapter table, nowhere else.
8. Keep Pigeon as the only Flutter-native bridge. Regenerate, do not hand-edit, generated code.
9. Use small commits per task, and explain any deviation from this PRD in the commit message.
10. If a requirement is impossible on Android (for example profile targeting, or hooking hard-coded WebViews), say so and stop. Do not use Accessibility Service workarounds.

## 18. Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Visible latency in the router | Uninstalls | Native-only path, in-memory rules, benchmark gates |
| Browser private-mode extras change or are ignored | Broken feature | Capability table, per-version testing, graceful fallback, honest UI |
| Source app unknown or spoofable | Wrong rule match | Treat as a hint, degrade to non-source rules, never use for security |
| Users expect in-app browsers to be intercepted | Bad reviews | Honest listing, onboarding, Help guide, share target |
| Trust as default browser | Adoption | No INTERNET permission, open privacy statement, optionally open source |
| Verified App Links bypass us | Confusion | Explain in Help; offer Open in app action where we do receive the link |
| Play policy or target API bumps | Rejection | Annual target API bump in the plan, avoid sensitive permissions |
| Rules file corruption | Lost config | Atomic writes, one backup copy, export reminder |

## 19. Open questions

1. Final product name and package id.
2. Open-source or closed source? (Affects licensing of the tracker list and trust positioning.)
3. Should history exist at all in v1, given the privacy positioning?
4. Is optional short-link expansion (needs network) worth a separate opt-in flavor in v2?
5. Which browsers are on the official verified list at launch, based on real device tests?
6. Tablet and foldable behavior of the picker under Android 17 adaptive requirements.

## 20. Appendix: manual test commands

```
# Fire a link at the default browser
adb shell am start -a android.intent.action.VIEW -d https://example.com/page?utm_source=test

# Check who holds the browser role (Android 10+)
adb shell cmd role get-role-holders android.app.role.BROWSER

# Measure router startup
adb shell am start -W -a android.intent.action.VIEW -d https://www.reddit.com/
```

For URLs with an ampersand, wrap the URL in single quotes inside the adb shell command.
