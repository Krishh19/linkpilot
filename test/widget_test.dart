import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';
import 'package:linkpilot/features/backup/backup_screen.dart';
import 'package:linkpilot/features/help/help_screen.dart';
import 'package:linkpilot/features/history/history_screen.dart';
import 'package:linkpilot/features/pro/pro_screen.dart';
import 'package:linkpilot/features/test_url/test_url_screen.dart';
import 'package:linkpilot/generated/linkpilot_api.g.dart';
import 'package:linkpilot/main.dart';

class FakeLinkPilotRepository implements LinkPilotRepository {
  final List<RulePigeon> rules = [];
  SettingsPigeon settings = SettingsPigeon(
    cleanerLevel: 'STANDARD',
    historyEnabled: false,
    historyRetentionDays: 7,
    schemaVersion: 1,
  );
  bool defaultBrowser = false;
  bool customTabsReady = true;

  @override
  Future<List<RulePigeon>> getRules() async => rules;

  @override
  Future<bool> saveRules(List<RulePigeon> newRules) async {
    rules.clear();
    rules.addAll(newRules);
    return true;
  }

  @override
  Future<SettingsPigeon> getSettings() async => settings;

  @override
  Future<bool> saveSettings(SettingsPigeon newSettings) async {
    settings = newSettings;
    return true;
  }

  @override
  Future<List<BrowserPigeon>> getInstalledBrowsers() async {
    return [
      BrowserPigeon(
        packageName: 'org.mozilla.firefox',
        label: 'Firefox',
        isDefault: false,
        usageCount: 5,
        privateModeStatus: 'VERIFIED',
      ),
      BrowserPigeon(
        packageName: 'com.android.chrome',
        label: 'Chrome',
        isDefault: true,
        usageCount: 2,
        privateModeStatus: 'BEST_EFFORT',
      ),
    ];
  }

  @override
  Future<BrowserSetupStatusPigeon> getBrowserSetupStatus() async {
    return BrowserSetupStatusPigeon(
      roleAvailable: true,
      roleHeld: defaultBrowser,
      qualifiesForBrowserRole: true,
      currentHandlerPackage: defaultBrowser
          ? 'com.linkpilot.app'
          : 'com.android.chrome',
      currentHandlerLabel: defaultBrowser ? 'LinkPilot' : 'Chrome',
      isLinkPilotHandler: defaultBrowser,
      customTabsReady: customTabsReady,
    );
  }

  @override
  Future<bool> requestDefaultBrowserRole() async {
    defaultBrowser = true;
    return true;
  }

  @override
  Future<bool> openDefaultAppsSettings() async => true;

  @override
  Future<RoutingResultPigeon> testRouteUrl(
    String url, {
    String? sourcePackage,
  }) async {
    return RoutingResultPigeon(
      cleanedUrl: 'https://example.com/clean',
      originalUrl: url,
      removedParams: ['utm_source'],
      sourcePackage: sourcePackage,
      decisionType: 'launch',
      matchedRuleId: 'test-rule',
      matchedRuleName: 'Test Rule',
      targetPackage: 'org.mozilla.firefox',
      mode: 'NORMAL',
    );
  }

  final List<HistoryItemPigeon> history = [];
  bool proUnlocked = false;

  @override
  Future<bool> openInBrowser(
    String url,
    String packageName, {
    String mode = 'NORMAL',
  }) async => true;

  @override
  Future<List<HistoryItemPigeon>> getHistory() async => history;

  @override
  Future<bool> clearHistory() async {
    history.clear();
    return true;
  }

  @override
  Future<bool> deleteHistoryItem(String id) async {
    history.removeWhere((h) => h.id == id);
    return true;
  }

  @override
  Future<String> exportBackupJson() async => '{"schemaVersion":1,"rules":[]}';

  @override
  Future<BackupSummaryPigeon> importBackupJson(
    String json, {
    required bool merge,
  }) async {
    return BackupSummaryPigeon(ruleCount: 0, schemaVersion: 1, success: true);
  }

  @override
  Future<bool> isProUnlocked() async => proUnlocked;

  @override
  Future<bool> setProUnlocked(bool unlocked) async {
    proUnlocked = unlocked;
    return true;
  }

  bool onboardingCompleted = true;

  @override
  Future<bool> isOnboardingCompleted() async => onboardingCompleted;

  @override
  Future<bool> setOnboardingCompleted(bool completed) async {
    onboardingCompleted = completed;
    return true;
  }
}

void main() {
  testWidgets('LinkPilotApp smoke test loads HomeScreen', (
    WidgetTester tester,
  ) async {
    final fakeRepo = FakeLinkPilotRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [linkPilotRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const LinkPilotApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('LinkPilot'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('Browsers'), findsOneWidget);
  });

  testWidgets('Onboarding skip persists completion and opens Home', (
    WidgetTester tester,
  ) async {
    final fakeRepo = FakeLinkPilotRepository()..onboardingCompleted = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [linkPilotRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const LinkPilotApp(initialLocation: '/onboarding'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Setup LinkPilot'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(fakeRepo.onboardingCompleted, isTrue);
    expect(
      find.text("LinkPilot is not Android's Default Browser"),
      findsOneWidget,
    );
  });

  testWidgets(
    'Onboarding shows the current handler and grants the browser role',
    (WidgetTester tester) async {
      final fakeRepo = FakeLinkPilotRepository()..onboardingCompleted = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [linkPilotRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const LinkPilotApp(initialLocation: '/onboarding'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Set as Default Browser'), findsOneWidget);
      expect(find.text('Android currently opens web links in'), findsOneWidget);
      expect(find.text('Chrome (com.android.chrome)'), findsOneWidget);

      final setDefault = find.text('Set LinkPilot as Default');
      await tester.ensureVisible(setDefault);
      await tester.tap(setDefault);
      await tester.pumpAndSettle();

      expect(fakeRepo.defaultBrowser, isTrue);
      expect(find.text('Default Browser Set!'), findsOneWidget);
    },
  );

  testWidgets('Home names the app Android currently uses for web links', (
    WidgetTester tester,
  ) async {
    final fakeRepo = FakeLinkPilotRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [linkPilotRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const LinkPilotApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("LinkPilot is not Android's Default Browser"),
      findsOneWidget,
    );
    expect(
      find.textContaining('Android currently opens web links in'),
      findsOneWidget,
    );
    expect(find.text('Chrome (com.android.chrome)'), findsOneWidget);
    expect(find.text('Set LinkPilot as Default'), findsOneWidget);
  });

  testWidgets('Home confirms setup when LinkPilot is the default browser', (
    WidgetTester tester,
  ) async {
    final fakeRepo = FakeLinkPilotRepository()..defaultBrowser = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [linkPilotRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const LinkPilotApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LinkPilot is your Default Browser'), findsOneWidget);
    expect(
      find.text('Every tapped web link is routed through LinkPilot.'),
      findsOneWidget,
    );
    expect(find.text('Set LinkPilot as Default'), findsNothing);
  });

  testWidgets('HelpScreen renders in-app browser guides and honesty policy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Help & App Guides'), findsOneWidget);
    expect(find.text('Bypass In-App Browsers'), findsOneWidget);
    expect(find.text('Reddit'), findsOneWidget);
    expect(find.text('X (Twitter)'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
  });

  testWidgets('TestUrlScreen performs route evaluation', (
    WidgetTester tester,
  ) async {
    final fakeRepo = FakeLinkPilotRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [linkPilotRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: TestUrlScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test URL Against Native Engine'), findsOneWidget);
    expect(find.text('Evaluate Route'), findsOneWidget);

    // Tap Evaluate Route button
    await tester.tap(find.text('Evaluate Route'));
    await tester.pumpAndSettle();

    expect(find.text('Decision: Direct Launch'), findsOneWidget);
    expect(find.text('Test Rule'), findsOneWidget);
  });

  testWidgets('HistoryScreen renders disabled state and enables history', (
    WidgetTester tester,
  ) async {
    final fakeRepo = FakeLinkPilotRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [linkPilotRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('History is Disabled'), findsOneWidget);
    expect(find.text('Enable Routing History'), findsOneWidget);

    // Tap Enable
    await tester.tap(find.text('Enable Routing History'));
    await tester.pumpAndSettle();

    expect(fakeRepo.settings.historyEnabled, isTrue);
    expect(find.text('No routed links in history yet.'), findsOneWidget);
  });

  testWidgets('BackupScreen renders export and import cards', (
    WidgetTester tester,
  ) async {
    final fakeRepo = FakeLinkPilotRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [linkPilotRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: BackupScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Export Configuration'), findsOneWidget);
    expect(find.text('Import Configuration'), findsOneWidget);
    expect(find.text('Export Rules & Settings'), findsOneWidget);
    expect(find.text('Merge with Existing'), findsOneWidget);
    expect(find.text('Replace All'), findsOneWidget);
  });

  testWidgets('ProScreen renders features and handles unlock', (
    WidgetTester tester,
  ) async {
    final fakeRepo = FakeLinkPilotRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [linkPilotRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: ProScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to LinkPilot Pro'), findsOneWidget);
    expect(find.text('Saved Routing Rules'), findsOneWidget);

    final unlockFinder = find.text('Unlock Pro (One-Time Purchase)');
    await tester.scrollUntilVisible(unlockFinder, 200);

    expect(unlockFinder, findsOneWidget);

    // Tap unlock
    await tester.tap(unlockFinder);
    await tester.pumpAndSettle();

    expect(fakeRepo.proUnlocked, isTrue);
    expect(find.text('LinkPilot Pro Active'), findsOneWidget);
  });
}
