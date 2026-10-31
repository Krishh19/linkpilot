import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/generated/linkpilot_api.g.dart',
    kotlinOut: 'android/app/src/main/kotlin/com/linkpilot/app/pigeon/LinkPilotApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.linkpilot.app.pigeon'),
  ),
)
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

class BrowserSetupStatusPigeon {
  BrowserSetupStatusPigeon({
    required this.roleAvailable,
    required this.roleHeld,
    required this.qualifiesForBrowserRole,
    this.currentHandlerPackage,
    this.currentHandlerLabel,
    required this.isLinkPilotHandler,
    required this.customTabsReady,
  });

  bool roleAvailable;
  bool roleHeld;
  bool qualifiesForBrowserRole;
  String? currentHandlerPackage;
  String? currentHandlerLabel;
  bool isLinkPilotHandler;
  bool customTabsReady;
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

class HistoryItemPigeon {
  HistoryItemPigeon({
    required this.id,
    required this.url,
    required this.targetPackage,
    required this.timestampEpochMs,
  });

  String id;
  String url;
  String targetPackage;
  int timestampEpochMs;
}

class BackupSummaryPigeon {
  BackupSummaryPigeon({
    required this.ruleCount,
    required this.schemaVersion,
    required this.success,
    this.errorMessage,
  });

  int ruleCount;
  int schemaVersion;
  bool success;
  String? errorMessage;
}

@HostApi()
abstract class LinkPilotHostApi {
  List<RulePigeon> getRules();
  bool saveRules(List<RulePigeon> rules);
  SettingsPigeon getSettings();
  bool saveSettings(SettingsPigeon settings);
  List<BrowserPigeon> getInstalledBrowsers();
  BrowserSetupStatusPigeon getBrowserSetupStatus();
  bool requestDefaultBrowserRole();
  bool openDefaultAppsSettings();
  RoutingResultPigeon testRouteUrl(String url, String? sourcePackage);
  bool openInBrowser(String url, String packageName, String mode);

  // History & Purge (FR-H)
  List<HistoryItemPigeon> getHistory();
  bool clearHistory();
  bool deleteHistoryItem(String id);

  // Backup & Restore (FR-I)
  String exportBackupJson();
  BackupSummaryPigeon importBackupJson(String json, bool merge);

  // Pro & Free Tier (FR-J)
  bool isProUnlocked();
  bool setProUnlocked(bool unlocked);

  // First-run setup
  bool isOnboardingCompleted();
  bool setOnboardingCompleted(bool completed);
}
