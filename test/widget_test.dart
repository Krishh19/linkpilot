import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';
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
    expect(find.text('Test URL Routing'), findsOneWidget);
  });
}
