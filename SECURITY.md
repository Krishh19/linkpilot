# Security Policy

LinkPilot handles URLs, browser intents, clipboard actions, and local routing
data. We take reports about privacy leaks, intent handling, and local data
exposure seriously.

## Supported versions

| Version | Supported |
| --- | --- |
| 1.0.x | Yes |
| < 1.0 | No |

LinkPilot is Android-only. Fixes are made on the default branch and released as
new builds; there are no long-term support branches.

## Report a vulnerability privately

Please do **not** open a public issue for a security or privacy problem.

1. Open the repository's **Security** tab.
2. If private vulnerability reporting is available, choose **Report a
   vulnerability** and submit the details there.
3. If it is not available, contact the project maintainers privately through the
   contact options on the repository owner's GitHub profile. Do not include
   exploit details in a public issue, discussion, or pull request.

We will acknowledge a complete report as soon as practical and keep you informed
about the assessment and remediation. This is a volunteer project, so these are
best-effort commitments rather than a commercial service-level agreement.

## What to include

- LinkPilot version (from the APK or repository commit)
- Android version and device model
- A description of the impact and the affected component
- Reproduction steps or a minimal proof of concept
- Relevant logs with all URLs, titles, clipboard text, account names, and device
  identifiers removed

## What not to include

- Real browsing URLs, history entries, or clipboard contents
- Personal data belonging to you or anyone else
- Credentials, tokens, or signing keys
- A public proof-of-concept before a fix is available

## Scope

In scope:

- URL parsing, validation, redirect unwrapping, and tracking-parameter removal
- Rule matching, priority, and bypasses that send a link to the wrong app
- Intent handling in `RouterActivity`, including exported components and
  redirection issues
- Custom Tabs service behavior
- Clipboard access from the Quick Settings tile or launcher shortcut
- Backup import parsing and local storage of rules, settings, or history
- Accidental URL logging or telemetry
- Permission or manifest regressions, especially `INTERNET` or
  `QUERY_ALL_PACKAGES`
- Release build hardening, R8 rules, and exported-component configuration

Out of scope:

- Vulnerabilities in Chrome, Firefox, Reddit, or another third-party app
- The fact that a third-party app pins its own browser or uses a WebView and
  therefore bypasses the Android default-browser role
- Behavior that requires a rooted device, a modified system, or an unlocked
  bootloader
- Social engineering and physical-access attacks
- Missing hardening that has no demonstrated security or privacy impact

## Privacy expectations

LinkPilot is designed to work offline:

- No `INTERNET` permission in the release manifest
- No analytics, advertising, crash-reporting, or cloud-sync SDKs
- No URL, title, clipboard, or source-app logging
- History is opt-in and stored only in app-private storage
- The clipboard is read only after the user explicitly triggers the tile,
  shortcut, or share flow

If you find behavior that contradicts any of these statements, treat it as a
security or privacy report.

## No bug bounty

There is no paid bug bounty program. We are happy to credit reporters in the
release notes when they ask to be credited.
