# LinkPilot

**Your links, your browser.** LinkPilot is a private, offline Android link router. It becomes your default browser, then sends each tapped link to the browser and mode you choose - by site, by source app, or through an explicit picker.

LinkPilot is built for people who want `github.com` links to open in Firefox, Reddit links in a private tab, and work links in Chrome, without giving up privacy or installing a browser with a cloud backend.

## Why LinkPilot

Android sends every web link to one app: the system default browser. Choosing a "favorite browser" inside another app does not change that. LinkPilot takes the default-browser role, inspects each link natively, and forwards it to the right app.

- Routing happens in Kotlin before Flutter starts, so tapping a link does not pay the Flutter startup cost.
- No `INTERNET` permission, no analytics, no ads, and no crash-reporting SDKs.
- Rules, settings, and optional history stay in the app's private storage.

## Features

### Routing

- Exact-domain, wildcard-domain (`*.example.com`), and optional bounded regex rules.
- Source-app rules, such as "links opened from Reddit go to Firefox".
- Rule priority, then specificity, then creation order decide the winner.
- Global fallback browser when no rule matches.
- In-app picker with **Just once**, **Always for site**, and **Always from app**.
- Private-mode routing where the target browser exposes a public intent extra.
- A native default-browser diagnostic that reports the actual Android handler, role status, eligibility, and Custom Tabs readiness.

### Link cleaning

- Removes common tracking parameters such as `utm_*`, `fbclid`, `gclid`, `msclkid`, and `igshid`.
- Domain-specific parameter rules for X/Twitter, YouTube, Spotify, Amazon, Reddit, and others.
- Unwraps redirect wrappers from Facebook, Reddit, Google, and Slack (up to three hops, loop-safe).
- Standard and aggressive cleaning levels, plus a safe-exception list for parameters that must survive.
- The picker shows what was removed and can open the original URL instead.

### Everyday actions

- Share a link to LinkPilot from any app.
- Open the copied link from a Quick Settings tile or launcher shortcut. The clipboard is read only after an explicit tap.
- Opt-in history with automatic retention purge.
- JSON backup and restore for rules and settings.
- Onboarding that refuses to silently finish when LinkPilot still cannot receive links.

### Privacy

- No network permission in the release manifest.
- No telemetry, advertising, cloud sync, or remote rule updates.
- URLs, titles, and source apps are never logged.
- History is off by default when you first install the app.
- No Accessibility Service. LinkPilot does not simulate taps or read other apps' screens.

## Requirements

| Component | Requirement |
| --- | --- |
| Android | 8.0 (API 26) or newer |
| Default-browser role | Android 10+ uses the system role dialog; Android 8-9 opens Default apps settings |
| Build JDK | 17 or newer (CI uses Temurin 21) |
| Flutter | 3.47.x stable |
| Dart | 3.13.5 |
| Android SDK | compileSdk / targetSdk 36 |

## Getting started

```bash
git clone <repository-url>
cd linkpilot
flutter pub get
flutter run
```

Release APK:

```bash
flutter build apk --release
# android/app/build/outputs/apk/release/app-release.apk
```

On Windows, use `android\gradlew.bat` for the Gradle commands below.

## Make LinkPilot your default browser

This step is required. Routing rules do not run until Android sends links to LinkPilot.

1. Install and open LinkPilot.
2. On the Home or onboarding screen, tap **Set LinkPilot as Default**.
3. Accept the Android role dialog, or choose LinkPilot under **Settings > Apps > Default apps > Browser app**.
4. Return to LinkPilot. The Home screen should say **LinkPilot is your Default Browser** and show LinkPilot as the current web-link handler.

Choosing a fallback browser inside LinkPilot does **not** grant the Android default-browser role. Android will keep using Chrome until the role is assigned to LinkPilot.

### Diagnose "it still opens Chrome"

Check what Android actually resolves for a web link:

```bash
adb shell cmd package resolve-activity --brief \
  -a android.intent.action.VIEW \
  -c android.intent.category.BROWSABLE \
  -d "https://example.com"
```

- `com.linkpilot.app/com.linkpilot.app.RouterActivity` means LinkPilot receives web links.
- A Chrome component means LinkPilot does not hold the default-browser role.
- If the resolver shows LinkPilot but one specific app still opens Chrome, that app is bypassing the default browser (for example with a pinned Custom Tab or a hard-coded WebView). Use that app's **Share > LinkPilot** flow instead. This cannot be fixed without an Accessibility Service, which LinkPilot deliberately does not use.

More device checks are in [docs/browser-capabilities.md](docs/browser-capabilities.md).

## How it works

```text
Link tap, share, tile, or shortcut
  |
  v
RouterActivity (Kotlin, no Flutter engine)
  |
  +-- :core  validate -> unwrap redirects -> strip trackers -> match rules -> decide
  |
  +-- :platform  launch the chosen browser or show the Compose picker
  |
  +-- optional history / usage counters (app-private storage)
```

The Flutter UI is only used for settings, rule management, history, backup, and onboarding:

```text
Flutter screen -> Pigeon -> LinkPilotHostApiImpl -> :platform / :core
```

### Modules

| Path | Responsibility |
| --- | --- |
| `android/core` | Pure Kotlin/JVM routing engine: URL parsing, cleaning, matching, rule drafts. No Android imports. |
| `android/platform` | Android implementations: browser discovery, launch quirks, picker, storage. |
| `android/app` | Native `RouterActivity`, Custom Tabs provider, Quick Settings tile, Pigeon host, Flutter host. |
| `lib` | Flutter settings and management UI. |
| `pigeons` | The single Flutter-native bridge definition. Generated files are checked in. |
| `docs` | ADRs and the empirical browser capability matrix. |

Routing and cleaning logic must live only in `:core`. See [AGENTS.md](AGENTS.md) for the project invariants.

## Browser support

LinkPilot routes to any installed app that handles `https` links. Private-mode routing is best-effort because browsers do not share one standard:

- **Verified by architecture:** Firefox Focus, DuckDuckGo.
- **Best effort:** Firefox, Firefox Beta, Firefox Nightly, Chrome, Brave, Edge, Vivaldi.
- **Unsupported for private mode:** Opera, Opera Mini, Samsung Internet. These still open normally.

The authoritative table and device-test notes are in [docs/browser-capabilities.md](docs/browser-capabilities.md) and [docs/decisions.md](docs/decisions.md).

## Project status

- This repository contains the Android implementation only.
- The release build currently signs with the debug keystore so that APKs are easy to test. Configure a real keystore before publishing to a store.
- LinkPilot Pro is a feature tier with unlimited rules, source-app rules, automated private mode, aggressive cleaning, and full backup/restore. The app currently exposes a local unlock flag for testing; Play Billing is not wired yet.
- Browser-specific behavior is empirical. An intent extra is not considered verified until a physical-device test is recorded.

## Testing

```bash
flutter analyze
flutter test

cd android
./gradlew :core:test :app:testDebugUnitTest :platform:testDebugUnitTest
```

The suite includes JVM tests for the routing engine, manifest/privacy audit tests, and Flutter widget tests for setup and routing UI.

Device smoke scenarios:

```bash
adb devices
bash tools/adb_scenarios.sh
```

Manual checks are required for anything that depends on a browser or a calling app, including Custom Tabs interception, private-mode extras, and default-browser behavior.

## Limitations

- Android only. There is no iOS, web, or desktop version.
- Pinned Custom Tabs and hard-coded WebViews cannot be intercepted without an Accessibility Service.
- Browser profiles (for example a work profile inside Chrome) cannot be targeted through public intent APIs.
- Private-mode support depends on each browser's public intent extras.
- Default-browser role assignment on Android 8-9 falls back to the system Default apps screen.
- LinkPilot cannot recover links from apps that never emit an `ACTION_VIEW` or share intent.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first, then open an issue or pull request using the templates in `.github/`.

- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security policy](SECURITY.md)
- [Changelog](CHANGELOG.md)
- [Architecture decisions](docs/decisions.md)
- [Browser capability matrix](docs/browser-capabilities.md)
- [Product requirements](<LinkPilot PRD Android Link Router (Flutter + Kotlin).md>)

Please do not paste real URLs, browsing history, clipboard contents, or other personal data into public issues.

## License

MIT. See [LICENSE](LICENSE).
