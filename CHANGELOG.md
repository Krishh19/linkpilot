# Changelog

All notable changes to LinkPilot are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Nothing yet.

### Changed

- Removed the Pro tier, upgrade screen, and five-rule free-tier limit. Every
  feature is now available for free, with no account, purchase, or billing code.

## [1.0.0] - 2026-10-31

First public repository release.

### Added

- Native Android link routing for `http` and `https` links, with no Flutter
  startup on the routing path.
- Exact-domain, wildcard-domain, optional bounded-regex, and source-app rules.
- Rule resolution by priority, specificity, and creation order.
- In-app browser picker with **Just once**, **Always for site**, and **Always
  from app** actions.
- Private-mode routing through the `BrowserAdapter` capability table, with
  honest fallback for browsers that do not expose a public intent extra.
- Tracking-parameter removal and redirect unwrapping for common wrappers.
- Standard and aggressive cleaner levels with domain-specific rules and safe
  exceptions.
- Share target for text links.
- Quick Settings tile and launcher shortcut for opening the copied link only on
  user request.
- Opt-in routing history with retention purge and manual deletion.
- JSON backup and restore for rules, settings, and usage counters.
- Onboarding with default-browser setup and a gate that warns when LinkPilot
  still cannot receive links.
- Home-screen diagnostics for role state, actual Android link handler,
  default-browser eligibility, and Custom Tabs readiness.
- Custom Tabs provider so apps that consult the default browser can hand links
  to LinkPilot.
- JVM routing tests, manifest/privacy audit tests, Flutter widget tests, and ADB
  scenario scripts.
- Architecture decision records and an empirical browser capability matrix.

### Changed

- Source-app detection now prefers `launchedFromPackage` on Android 14+ and
  falls back to the referrer and calling package.
- Site rules created from a `www.` host now cover the apex domain and all
  subdomains instead of duplicating the `www` label in the wildcard.
- The router shows the system chooser when no supported browser is installed,
  rather than finishing silently.
- Relaunching a routing rule now reports launch failures instead of recording a
  successful history entry.

### Fixed

- Cleaner rules are loaded from the packaged Flutter asset path, so native
  routing no longer starts with an empty cleaner configuration.
- Onboarding completion is persisted through the native storage layer and
  survives process restarts.
- Invalid schemes and over-long URLs are rejected with a toast instead of
  opening a picker.
- Custom Tabs from apps such as Reddit are intercepted when LinkPilot holds the
  Android default-browser role.

### Security

- Release manifest keeps `INTERNET` and `QUERY_ALL_PACKAGES` out of the app;
  the privacy audit test enforces this.
- No analytics, advertising, crash-reporting, or cloud SDKs.
- URLs and clipboard contents are never logged.
- The clipboard is accessed only from an explicit user action.
