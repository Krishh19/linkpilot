#!/usr/bin/env bash
# LinkPilot: ADB Link Routing Test Scenarios
set -euo pipefail

PACKAGE="com.linkpilot.app"
ROUTER_ACTIVITY="${PACKAGE}/com.linkpilot.platform.RouterActivity"

echo "=== LinkPilot ADB Test Scenarios ==="

# Scenario 1: Standard HTTP URL
echo "Scenario 1: Testing standard HTTP URL..."
adb shell am start -a android.intent.action.VIEW -d "http://example.com" -n "${ROUTER_ACTIVITY}"

# Scenario 2: HTTPS URL with tracking parameters (UTM, FBCLID)
echo "Scenario 2: Testing URL with UTM and tracking params..."
adb shell am start -a android.intent.action.VIEW -d "'https://www.example.com/article?utm_source=twitter&utm_medium=social&fbclid=IwAR123'" -n "${ROUTER_ACTIVITY}"

# Scenario 3: Wildcard domain rule test (e.g., Reddit)
echo "Scenario 3: Testing Reddit link..."
adb shell am start -a android.intent.action.VIEW -d "https://old.reddit.com/r/android" -n "${ROUTER_ACTIVITY}"

# Scenario 4: URL with wrapper/redirect (e.g. Google redirect or Facebook shim)
echo "Scenario 4: Testing Facebook linkshim..."
adb shell am start -a android.intent.action.VIEW -d "'https://l.facebook.com/l.php?u=https%3A%2F%2Fclean-target.org%2Fpage%3Futm_content%3Djunk'" -n "${ROUTER_ACTIVITY}"

# Scenario 5: Malformed / non-http scheme (should safely terminate with no crash)
echo "Scenario 5: Testing invalid scheme (should safely drop)..."
adb shell am start -a android.intent.action.VIEW -d "ftp://example.com/file" -n "${ROUTER_ACTIVITY}" || true

echo "=== All ADB Scenarios Injected ==="
