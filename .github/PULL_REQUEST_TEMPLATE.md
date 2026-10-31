## Summary

<!-- What changed and why? Focus on user-visible behavior. -->

## Related issue

<!-- Link the issue, or write "None". -->

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Refactor
- [ ] Documentation
- [ ] Build, CI, or tooling

## Test plan

- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `cd android && ./gradlew :core:test :app:testDebugUnitTest :platform:testDebugUnitTest`
- [ ] Physical-device check, when the change touches intents, browsers, Custom Tabs, the clipboard, or the default-browser role

Device check details (device, Android version, browser versions, result):

```text

```

## Privacy and security

- [ ] No URL, page title, clipboard text, or source app is logged.
- [ ] No analytics, advertising, crash-reporting, or network library was added.
- [ ] No `INTERNET` or `QUERY_ALL_PACKAGES` permission was added. If an exception is proposed, it is recorded in `docs/decisions.md`.
- [ ] Browser-specific intent extras were verified on a device and added only to the `BrowserAdapterTable`.
- [ ] Routing, cleaning, and matching logic remains in `:core` and is not duplicated in Dart.
- [ ] Pigeon changes were regenerated with `dart run pigeon --input pigeons/linkpilot_api.dart`; generated files were not hand-edited.
- [ ] The router path still starts no Flutter, billing, Room, or analytics work.

## Screenshots or recordings

<!-- Optional. Redact URLs, history, clipboard contents, and account names. -->

## Notes for reviewers

<!-- Deviations from the PRD, follow-up work, or known limitations. -->
