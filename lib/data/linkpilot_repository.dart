import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkpilot/generated/linkpilot_api.g.dart';

final linkPilotApiProvider = Provider<LinkPilotHostApi>((ref) {
  return LinkPilotHostApi();
});

final linkPilotRepositoryProvider = Provider<LinkPilotRepository>((ref) {
  final api = ref.watch(linkPilotApiProvider);
  return LinkPilotRepository(api);
});

class LinkPilotRepository {
  LinkPilotRepository(this._api);

  final LinkPilotHostApi _api;

  Future<List<RulePigeon>> getRules() async {
    return _api.getRules();
  }

  Future<bool> saveRules(List<RulePigeon> rules) async {
    return _api.saveRules(rules);
  }

  Future<SettingsPigeon> getSettings() async {
    return _api.getSettings();
  }

  Future<bool> saveSettings(SettingsPigeon settings) async {
    return _api.saveSettings(settings);
  }

  Future<List<BrowserPigeon>> getInstalledBrowsers() async {
    return _api.getInstalledBrowsers();
  }

  Future<BrowserSetupStatusPigeon> getBrowserSetupStatus() async {
    return _api.getBrowserSetupStatus();
  }

  Future<bool> requestDefaultBrowserRole() async {
    return _api.requestDefaultBrowserRole();
  }

  Future<bool> openDefaultAppsSettings() async {
    return _api.openDefaultAppsSettings();
  }

  Future<RoutingResultPigeon> testRouteUrl(
    String url, {
    String? sourcePackage,
  }) async {
    return _api.testRouteUrl(url, sourcePackage);
  }

  Future<bool> openInBrowser(
    String url,
    String packageName, {
    String mode = 'NORMAL',
  }) async {
    return _api.openInBrowser(url, packageName, mode);
  }

  Future<List<HistoryItemPigeon>> getHistory() async {
    return _api.getHistory();
  }

  Future<bool> clearHistory() async {
    return _api.clearHistory();
  }

  Future<bool> deleteHistoryItem(String id) async {
    return _api.deleteHistoryItem(id);
  }

  Future<String> exportBackupJson() async {
    return _api.exportBackupJson();
  }

  Future<BackupSummaryPigeon> importBackupJson(
    String json, {
    required bool merge,
  }) async {
    return _api.importBackupJson(json, merge);
  }

  Future<bool> isProUnlocked() async {
    return _api.isProUnlocked();
  }

  Future<bool> setProUnlocked(bool unlocked) async {
    return _api.setProUnlocked(unlocked);
  }

  Future<bool> isOnboardingCompleted() async {
    return _api.isOnboardingCompleted();
  }

  Future<bool> setOnboardingCompleted(bool completed) async {
    return _api.setOnboardingCompleted(completed);
  }
}
