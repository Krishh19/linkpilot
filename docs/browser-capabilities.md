# Browser Capabilities Matrix

This document tracks verified Android browser capabilities for link routing, specifically private/incognito mode intents and custom tab behavior.

> **Rule:** Every entry must be verified on a physical device or emulator before marking as `VERIFIED`. Never assume intent extras or component names.

| Browser | Package Name | Verified Version | Private Tab Intent Extras / Action | Status | Last Tested Date | Notes |
|---|---|---|---|---|---|---|
| Firefox | `org.mozilla.firefox` | - | `Boolean extra: "private_browsing_mode"` / Action: `org.mozilla.firefox.ACTION_OPEN_PRIVATE_TAB` | UNVERIFIED | - | Needs device verification |
| Firefox Focus | `org.mozilla.focus` | - | Always private | UNVERIFIED | - | Native focus is inherently private |
| Google Chrome | `com.android.chrome` | - | `Boolean extra: "com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB"` (Deprecated / restricted in recent versions) | UNVERIFIED | - | Often ignored on recent Android/Chrome versions |
| Brave | `com.brave.browser` | - | Chrome fork extras | UNVERIFIED | - | Needs verification |
| DuckDuckGo | `com.duckduckgo.mobile.android` | - | Component/Action or always private | UNVERIFIED | - | Needs verification |
| Microsoft Edge | `com.microsoft.emmx` | - | Chrome fork extras / InPrivate | UNVERIFIED | - | Needs verification |
| Opera | `com.opera.browser` | - | TBD | UNVERIFIED | - | Needs verification |
| Vivaldi | `com.vivaldi.browser` | - | Chrome fork extras | UNVERIFIED | - | Needs verification |
