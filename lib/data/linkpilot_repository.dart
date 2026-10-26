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

  Future<bool> isDefaultBrowser() async {
    return _api.isDefaultBrowser();
  }

  Future<bool> requestDefaultBrowserRole() async {
    return _api.requestDefaultBrowserRole();
  }

  Future<RoutingResultPigeon> testRouteUrl(String url, {String? sourcePackage}) async {
    return _api.testRouteUrl(url, sourcePackage);
  }

  Future<bool> openInBrowser(String url, String packageName, {String mode = 'NORMAL'}) async {
    return _api.openInBrowser(url, packageName, mode);
  }
}
