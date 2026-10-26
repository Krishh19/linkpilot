import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';
import 'package:linkpilot/generated/linkpilot_api.g.dart';

final defaultBrowserStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(linkPilotRepositoryProvider);
  return repo.isDefaultBrowser();
});

final installedBrowsersProvider = FutureProvider<List<BrowserPigeon>>((ref) async {
  final repo = ref.watch(linkPilotRepositoryProvider);
  return repo.getInstalledBrowsers();
});

class RulesNotifier extends AsyncNotifier<List<RulePigeon>> {
  @override
  Future<List<RulePigeon>> build() async {
    final repo = ref.watch(linkPilotRepositoryProvider);
    final rules = await repo.getRules();
    // Sort rules by priority descending
    rules.sort((a, b) => b.priority.compareTo(a.priority));
    return rules;
  }

  Future<void> saveRules(List<RulePigeon> updated) async {
    state = const AsyncLoading();
    final repo = ref.read(linkPilotRepositoryProvider);
    await repo.saveRules(updated);
    updated.sort((a, b) => b.priority.compareTo(a.priority));
    state = AsyncData(updated);
  }

  Future<void> addRule(RulePigeon rule) async {
    final current = state.value ?? [];
    final updated = [...current, rule];
    await saveRules(updated);
  }

  Future<void> updateRule(RulePigeon rule) async {
    final current = state.value ?? [];
    final updated = current.map((r) => r.id == rule.id ? rule : r).toList();
    await saveRules(updated);
  }

  Future<void> deleteRule(String id) async {
    final current = state.value ?? [];
    final updated = current.where((r) => r.id != id).toList();
    await saveRules(updated);
  }

  Future<void> toggleRule(String id) async {
    final current = state.value ?? [];
    final updated = current.map((r) {
      if (r.id == id) {
        r.enabled = !r.enabled;
      }
      return r;
    }).toList();
    await saveRules(updated);
  }
}

final rulesProvider = AsyncNotifierProvider<RulesNotifier, List<RulePigeon>>(RulesNotifier.new);

class SettingsNotifier extends AsyncNotifier<SettingsPigeon> {
  @override
  Future<SettingsPigeon> build() async {
    final repo = ref.watch(linkPilotRepositoryProvider);
    return repo.getSettings();
  }

  Future<void> updateSettings(SettingsPigeon settings) async {
    state = const AsyncLoading();
    final repo = ref.read(linkPilotRepositoryProvider);
    await repo.saveSettings(settings);
    state = AsyncData(settings);
  }

  Future<void> setGlobalDefault(String? packageName) async {
    final current = state.value;
    if (current == null) return;
    current.globalDefaultBrowser = packageName;
    await updateSettings(current);
  }

  Future<void> setCleanerLevel(String level) async {
    final current = state.value;
    if (current == null) return;
    current.cleanerLevel = level;
    await updateSettings(current);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsPigeon>(SettingsNotifier.new);
