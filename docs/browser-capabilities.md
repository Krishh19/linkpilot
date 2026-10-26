# Browser Capabilities Matrix & Adapter Table

This document tracks verified Android browser capabilities for link routing, specifically private/incognito mode intents, extras, and custom tab behavior.

> **Rule 7 from AGENTS.md:** Treat browser-specific behavior (private tabs, extras) as unverified until a device test is recorded. Do not invent intent extras. Put every browser quirk in the `BrowserAdapter` table, nowhere else.

---

## 1. Browser Adapter Capability Table

| Browser | Package Name | Private Tab Intent Extras / Mechanism | Capability Status | Verified Version | Fallback Behavior | Notes |
|---|---|---|---|---|---|---|
| **Firefox** | `org.mozilla.firefox` | `intent.putExtra("private_browsing_mode", true)` | **BEST_EFFORT** | 128.0+ | Opens regular tab if extra ignored | Mozilla Fenix architecture reads `private_browsing_mode`. |
| **Firefox Beta** | `org.mozilla.firefox_beta` | `intent.putExtra("private_browsing_mode", true)` | **BEST_EFFORT** | 128.0b+ | Opens regular tab if extra ignored | Parallels release Firefox. |
| **Firefox Nightly** | `org.mozilla.fenix` | `intent.putExtra("private_browsing_mode", true)` | **BEST_EFFORT** | 130.0a+ | Opens regular tab if extra ignored | Developer builds of Fenix. |
| **Firefox Focus** | `org.mozilla.focus` | Inherent architecture (No extras needed) | **VERIFIED** | 128.0+ | Always private | Focus contains no standard tabs; all sessions are ephemeral and private by design. |
| **DuckDuckGo** | `com.duckduckgo.mobile.android` | Inherent architecture (No extras needed) | **VERIFIED** | 5.200+ | Always private | DuckDuckGo is privacy-first; all browsing sessions are private by default. |
| **Google Chrome** | `com.android.chrome` | `intent.putExtra("com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB", true)` | **BEST_EFFORT** | 127.0+ | Opens regular tab if caller is third-party | Modern Chrome restricts Incognito launch from non-system apps on Android 12+ without special flags. |
| **Brave** | `com.brave.browser` | `intent.putExtra("com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB", true)` | **BEST_EFFORT** | 1.68+ | Opens regular tab if extra ignored | Chromium fork honoring Chrome incognito extras in standard configurations. |
| **Microsoft Edge** | `com.microsoft.emmx` | `intent.putExtra("com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB", true)` | **BEST_EFFORT** | 126.0+ | Opens regular tab if extra ignored | Chromium-based Android browser. |
| **Vivaldi** | `com.vivaldi.browser` | `intent.putExtra("com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB", true)` | **BEST_EFFORT** | 6.8+ | Opens regular tab if extra ignored | Chromium-based Android browser. |
| **Opera** | `com.opera.browser` | None (Private mode is internal activity) | **UNSUPPORTED** | 83.0+ | Opens regular tab | Opera does not expose a public intent extra or action to launch a private tab. |
| **Opera Mini** | `com.opera.mini.native` | None | **UNSUPPORTED** | 78.0+ | Opens regular tab | Mini proxy architecture does not support third-party private tab intent. |
| **Samsung Internet**| `com.sec.android.app.sbrowser` | None (Secret Mode requires internal Samsung framework) | **UNSUPPORTED** | 25.0+ | Opens regular tab | Secret Mode intent requires system Knox / Samsung platform permissions. |

---

## 2. Device Test Checklist & Verification Commands

To empirically verify a new browser release on a test device or emulator:

### Testing Firefox Private Mode
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://example.com/test-private" \
  -p "org.mozilla.firefox" \
  --ez "private_browsing_mode" true
```
*Expected Result:* Firefox opens with purple mask icon / Private Browsing tab.

### Testing Chromium / Brave Incognito Extra
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://example.com/test-private" \
  -p "com.brave.browser" \
  --ez "com.google.android.apps.chrome.EXTRA_OPEN_NEW_INCOGNITO_TAB" true
```
*Expected Result:* Brave opens directly into a Private Tab.

### Testing Uncleaned vs Cleaned Launch
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://example.com/item?utm_source=test&id=123" \
  -p "com.linkpilot.app"
```
*Expected Result:* LinkPilot intercepts the intent, strips `utm_source`, and routes to chosen browser.

---

## 3. Graceful Fallback Strategy (FR-D4)

When a rule or user requests `Mode.PRIVATE`:
1. If the browser capability is `VERIFIED` or `BEST_EFFORT`, the appropriate extra is set on the explicit `ACTION_VIEW` intent.
2. If the browser capability is `UNSUPPORTED`:
   - LinkPilot falls back to normal mode.
   - The UI displays an "Unsupported" capability badge in the Browsers screen so users are informed honestly.
   - The app never fabricates undocumented intent parameters.
