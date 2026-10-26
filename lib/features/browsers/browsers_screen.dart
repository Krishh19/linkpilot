import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkpilot/data/linkpilot_providers.dart';

class BrowsersScreen extends ConsumerWidget {
  const BrowsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browsersAsync = ref.watch(installedBrowsersProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Browsers'),
      ),
      body: browsersAsync.when(
        data: (browsers) {
          if (browsers.isEmpty) {
            return const Center(
              child: Text('No web browsers detected on this device.'),
            );
          }

          final currentGlobalDefault = settingsAsync.value?.globalDefaultBrowser;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: browsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final browser = browsers[index];
              final isGlobal = (browser.packageName == currentGlobalDefault);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              browser.label.isNotEmpty ? browser.label[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        browser.label,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (browser.isDefault) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withAlpha(40),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'OS Default',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  browser.packageName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (browser.usageCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${browser.usageCount} taps',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Private Mode Capability Badge
                      _buildCapabilityBadge(context, browser.privateModeStatus),

                      const SizedBox(height: 12),

                      // Global Default Toggle Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isGlobal)
                            FilledButton.tonalIcon(
                              onPressed: () {
                                ref.read(settingsProvider.notifier).setGlobalDefault(null);
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Default Browser in LinkPilot'),
                            )
                          else
                            OutlinedButton(
                              onPressed: () {
                                ref.read(settingsProvider.notifier).setGlobalDefault(browser.packageName);
                              },
                              child: const Text('Set as Fallback Browser'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading browsers: $err')),
      ),
    );
  }

  Widget _buildCapabilityBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    final (label, color, icon) = switch (status) {
      'VERIFIED' => ('Private tab: Verified on Android', Colors.green, Icons.verified_user),
      'BEST_EFFORT' => ('Private tab: Best effort intent extras', Colors.orange, Icons.info_outline),
      _ => ('Private tab: Not supported by browser', theme.colorScheme.outline, Icons.block),
    };

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
