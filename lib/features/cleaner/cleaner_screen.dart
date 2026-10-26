import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkpilot/data/linkpilot_providers.dart';

class CleanerScreen extends ConsumerWidget {
  const CleanerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final currentLevel = settingsAsync.value?.cleanerLevel ?? 'STANDARD';

    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Cleaner'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tracker Stripping & Redirect Unwrapping',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'LinkPilot strips tracking junk and unwraps redirect trampolines completely offline before opening any link.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 20),

          // Cleaner Level Selector
          Text(
            'Cleaning Level',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildLevelOption(
            context,
            ref,
            level: 'STANDARD',
            currentLevel: currentLevel,
            title: 'Standard (Recommended)',
            description: 'Strips known global marketing trackers (utm_*, fbclid, gclid, etc.) and per-site tracking parameters (X, YouTube, TikTok, Spotify). Safe exceptions like video timestamps are strictly preserved.',
          ),

          const SizedBox(height: 12),

          _buildLevelOption(
            context,
            ref,
            level: 'AGGRESSIVE',
            currentLevel: currentLevel,
            title: 'Aggressive',
            description: 'Strips all standard trackers plus heuristic patterns: affiliate IDs (aff_*), tracking prefixes, and third-party click IDs.',
          ),

          const SizedBox(height: 12),

          _buildLevelOption(
            context,
            ref,
            level: 'OFF',
            currentLevel: currentLevel,
            title: 'Off',
            description: 'Disables tracking parameter removal. Redirect unwrapping still functions to resolve destination links.',
          ),

          const SizedBox(height: 24),

          // Redirect Unwrappers Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Redirect Unwrapping',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LinkPilot automatically extracts the true destination URL from intermediary redirect wrappers (loop-safe, up to 3 hops) without making any network calls:',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Facebook link shim (l.facebook.com, lm.facebook.com)'),
                  const Text('• Reddit outbound wrapper (out.reddit.com)'),
                  const Text('• Google search redirect (google.com/url)'),
                  const Text('• Slack link wrapper (slack-redir.net)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Safe Exceptions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Safe Exceptions Preserved',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Legitimate query parameters that provide user functionality are safeguarded and never removed:',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  const Text('• YouTube video timestamps (?t=120s) and video IDs (?v=...)'),
                  const Text('• YouTube playlist and queue indexes (?list=..., ?index=...)'),
                  const Text('• Search queries, pagination (?page=...), and e-commerce filters'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelOption(
    BuildContext context,
    WidgetRef ref, {
    required String level,
    required String currentLevel,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final isSelected = (level == currentLevel);

    return Card(
      color: isSelected ? theme.colorScheme.primaryContainer.withAlpha(100) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref.read(settingsProvider.notifier).setCleanerLevel(level);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<String>(
                value: level,
                groupValue: currentLevel,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).setCleanerLevel(val);
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
