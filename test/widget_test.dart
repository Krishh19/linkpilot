import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';
import 'package:linkpilot/features/help/help_screen.dart';
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
  Future<bool> isDefaultBrowser() async => defaultBrowser;

  @override
  Future<bool> requestDefaultBrowserRole() async {
    defaultBrowser = true;
    return true;
  }

  @override
  Future<RoutingResultPigeon> testRouteUrl(String url, {String? sourcePackage}) async {
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

  @override
  Future<bool> openInBrowser(String url, String packageName, {String mode = 'NORMAL'}) async => true;
}

void main() {
  testWidgets('LinkPilotApp smoke test loads HomeScreen', (WidgetTester tester) async {
    final fakeRepo = FakeLinkPilotRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkPilotRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const LinkPilotApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('LinkPilot'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('Browsers'), findsOneWidget);
  });

  testWidgets('HelpScreen renders in-app browser guides and honesty policy', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HelpScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Help & App Guides'), findsOneWidget);
    expect(find.text('Bypass In-App Browsers'), findsOneWidget);
    expect(find.text('Reddit'), findsOneWidget);
    expect(find.text('X (Twitter)'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
  });

  testWidgets('TestUrlScreen performs route evaluation', (WidgetTester tester) async {
    final fakeRepo = FakeLinkPilotRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkPilotRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: TestUrlScreen(),
        ),
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
}
