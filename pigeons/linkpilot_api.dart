import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/linkpilot_api.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/com/linkpilot/app/pigeon/LinkPilotApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.linkpilot.app.pigeon',
  ),
))

class RulePigeon {
  RulePigeon({
    required this.id,
    this.name,
    required this.enabled,
    required this.priority,
    required this.domains,
    this.urlRegex,
    required this.sourcePackages,
    required this.actionType,
    this.targetPackage,
    this.mode,
    required this.createdAtEpochMs,
    required this.hitCount,
  });

  String id;
  String? name;
  bool enabled;
  int priority;
  List<String> domains;
  String? urlRegex;
  List<String> sourcePackages;
  String actionType; // "browser", "app", "ask"
  String? targetPackage;
  String? mode; // "NORMAL", "PRIVATE"
  int createdAtEpochMs;
  int hitCount;
}

class SettingsPigeon {
  SettingsPigeon({
    this.globalDefaultBrowser,
    required this.cleanerLevel,
    required this.historyEnabled,
    required this.historyRetentionDays,
    required this.schemaVersion,
  });

  String? globalDefaultBrowser;
  String cleanerLevel; // "OFF", "STANDARD", "AGGRESSIVE"
  bool historyEnabled;
  int historyRetentionDays;
  int schemaVersion;
}

class BrowserPigeon {
  BrowserPigeon({
    required this.packageName,
    required this.label,
    required this.isDefault,
    required this.usageCount,
    required this.privateModeStatus,
  });

  String packageName;
  String label;
  bool isDefault;
  int usageCount;
  String privateModeStatus; // "VERIFIED", "BEST_EFFORT", "UNSUPPORTED"
}

class RoutingResultPigeon {
  RoutingResultPigeon({
    required this.cleanedUrl,
    required this.originalUrl,
    required this.removedParams,
    this.sourcePackage,
    required this.decisionType, // "launch", "picker"
    this.matchedRuleId,
    this.matchedRuleName,
    this.targetPackage,
    this.mode,
    this.pickerReason,
  });

  String cleanedUrl;
  String originalUrl;
  List<String> removedParams;
  String? sourcePackage;
  String decisionType;
  String? matchedRuleId;
  String? matchedRuleName;
  String? targetPackage;
  String? mode;
  String? pickerReason;
}

@HostApi()
abstract class LinkPilotHostApi {
  List<RulePigeon> getRules();
  bool saveRules(List<RulePigeon> rules);
  SettingsPigeon getSettings();
  bool saveSettings(SettingsPigeon settings);
  List<BrowserPigeon> getInstalledBrowsers();
  bool isDefaultBrowser();
  bool requestDefaultBrowserRole();
  RoutingResultPigeon testRouteUrl(String url, String? sourcePackage);
  bool openInBrowser(String url, String packageName, String mode);
}
