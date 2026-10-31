# Contributing to LinkPilot

Thanks for helping improve LinkPilot. This project handles URLs, intents, and browser selection, so correctness and privacy matter more than feature count. Please read this guide and [AGENTS.md](AGENTS.md) before opening a pull request.

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Project invariants

These rules are not style preferences. A change that violates them will not be merged.

1. **Routing logic lives in `:core`.** Do not duplicate matching, cleaning, or URL parsing in Dart or in `:platform`.
2. **The router path stays native.** Never start Flutter, Room, billing, or analytics work from `RouterActivity`.
3. **No tracking or broad permissions.** Do not add network libraries, analytics, ads, or crash-reporting SDKs. Do not add `INTERNET` or `QUERY_ALL_PACKAGES` without an explicit ADR in [docs/decisions.md](docs/decisions.md).
4. **URLs are private.** Never log URLs, page titles, clipboard contents, or source apps in any build type.
5. **Tests ship with the code.** Add a test for acceptance criteria, or document the physical-device check when Android behavior cannot be tested off-device.
6. **Pin tooling versions.** Use the latest stable release at the time of the change and pin it in `android/gradle/libs.versions.toml` and `pubspec.lock`. Do not downgrade to hide a build error without recording why.
7. **Browser behavior must be empirical.** Do not invent intent extras. Private-mode behavior belongs in `BrowserAdapterTable` and is unverified until a device test is recorded.
8. **Pigeon is the only Flutter-native bridge.** Regenerate generated files; never hand-edit them.
9. **Commits are traceable.** Keep commits small and explain any deliberate deviation from the PRD in the commit message.
10. **Be honest about platform limits.** If Android cannot do something, document it and stop. Do not use an Accessibility Service workaround.

## Development setup

### Requirements

- Android 8.0 (API 26) or newer device or emulator for smoke testing
- JDK 17 or newer (CI uses Temurin 21)
- Flutter 3.47.x stable (Dart 3.13.5)
- Android SDK with compileSdk 36

### Install

```bash
flutter pub get
```

Run the Flutter settings UI:

```bash
flutter run
```

The native `RouterActivity` is exercised by tapping a link while LinkPilot holds the default-browser role. The Flutter UI and the router are separate entry points.

### Build

```bash
flutter build apk --release
```

The APK is written to `android/app/build/outputs/apk/release/app-release.apk`. The current release configuration signs with the debug keystore for testing. Use your own keystore for any distributed build.

## Architecture

```text
android/core      Pure Kotlin/JVM engine. No android.* imports.
android/platform  Android browser discovery, launchers, storage, Compose picker.
android/app       RouterActivity, Custom Tabs service, tile, Pigeon host, Flutter host.
lib               Flutter settings and management UI.
pigeons           Pigeon API definition.
```

Routing pipeline:

1. Validate the URL (http/https, maximum length).
2. Unwrap redirect wrappers up to three hops.
3. Remove tracking parameters according to the cleaner level and safe exceptions.
4. Match enabled rules by priority, specificity, then creation time.
5. Launch the selected browser, show the picker, or fall back to the system chooser.

See [README.md](README.md) and [docs/decisions.md](docs/decisions.md) for the rationale.

## Changing the Flutter-native bridge

`pigeons/linkpilot_api.dart` is the source of truth.

```bash
dart run pigeon --input pigeons/linkpilot_api.dart
```

This regenerates:

- `lib/generated/linkpilot_api.g.dart`
- `android/app/src/main/kotlin/com/linkpilot/app/pigeon/LinkPilotApi.g.kt`

Commit the regenerated files together with the Pigeon definition and the host implementation. Do not edit generated files by hand.

## Tests and checks

Run these before opening a pull request. Format only the Dart files you changed; do not reformat the whole tree in a feature PR.

```bash
dart format path/to/changed_file.dart
flutter analyze
flutter test

cd android
./gradlew :core:test :app:testDebugUnitTest :platform:testDebugUnitTest
```

On Windows:

```powershell
cd android
.\gradlew.bat :core:test :app:testDebugUnitTest :platform:testDebugUnitTest
```

The privacy and manifest audit test runs in `:app` and checks that prohibited permissions have not appeared.

### Device checks

Some behavior can only be verified on a physical device or a real Android runtime:

- Default-browser role assignment
- Custom Tabs interception from Reddit, Gmail, or another host app
- Private-mode extras for each browser
- Share target behavior
- Clipboard tile and launcher shortcut behavior

Useful commands:

```bash
adb shell cmd role get-role-holders android.app.role.BROWSER
adb shell cmd package resolve-activity --brief \
  -a android.intent.action.VIEW \
  -c android.intent.category.BROWSABLE \
  -d "https://example.com"
bash tools/adb_scenarios.sh
```

Record the device model, Android version, browser versions, and the result in the pull request when a change depends on browser behavior. Never include a real browsing URL or personal data in the report.

## Pull requests

1. Open an issue for non-trivial changes so the approach can be agreed on first.
2. Keep the change focused. Separate refactors from behavior changes.
3. Add or update tests. If a test is impossible, explain the manual check.
4. Update documentation and ADRs when behavior or a platform limit changes.
5. Confirm that no URL, title, clipboard text, or source app is logged.
6. Confirm that no network or broad package-visibility permission was added.
7. Describe the user-visible effect and the test plan in the PR body.

Use [Conventional Commits](https://www.conventionalcommits.org/) style, for example:

```text
fix(router): keep wildcard site rules on the apex domain
feat(picker): remember the last selected browser
docs: record the Custom Tabs limitation
```

## Reporting bugs and security issues

- Functional bugs: use the issue templates in `.github/ISSUE_TEMPLATE/`.
- Security or privacy problems: do **not** open a public issue. Follow [SECURITY.md](SECURITY.md).

Before posting logs or screenshots, remove URLs, browsing history, clipboard contents, account names, and device identifiers.

## License

By contributing, you agree that your contribution is licensed under the [MIT License](LICENSE).
