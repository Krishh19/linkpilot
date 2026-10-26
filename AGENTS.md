# LinkPilot: Rules for AI Coding Agent

1. **Single Source of Truth for Routing Logic**: Routing and rule logic exist only in `:core`. Never duplicate matching or cleaning logic in Dart.
2. **Zero Flutter Overhead on Route Path**: Never start the Flutter engine or initialize Room, Billing, or analytics-like code on the router path.
3. **No Tracking & Strict Permissions**: Never add network libraries, analytics, ad, or crash-reporting SDKs. Never add `INTERNET` or `QUERY_ALL_PACKAGES` permissions without an explicit written decision recorded in `docs/decisions.md`.
4. **URL Privacy**: Never log URLs, titles, or source apps, in any build type.
5. **Test-Driven Delivery**: Write tests with the code. A feature is not done until its acceptance criteria have tests, or a documented manual check where a device is required.
6. **Tooling & Versions**: Prefer the latest stable versions at project start, use the newest patch release, and pin them in the version catalog and `pubspec.lock`. Do not downgrade tooling to silence a build error without recording why.
7. **Empirical Browser Capabilities**: Treat browser-specific behavior (private tabs, extras) as unverified until a device test is recorded. Do not invent intent extras. Put every browser quirk in the `BrowserAdapter` table, nowhere else.
8. **Pigeon Bridge Only**: Keep Pigeon as the only Flutter-native bridge. Regenerate, do not hand-edit, generated code.
9. **Traceable Git Commits**: Use small commits per task, and explain any deviation from this PRD in the commit message.
10. **Platform Honesty**: If a requirement is impossible on Android (for example profile targeting, or hooking hard-coded WebViews), say so and stop. Do not use Accessibility Service workarounds.
