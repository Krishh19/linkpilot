import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkpilot/data/linkpilot_providers.dart';

class ProScreen extends ConsumerWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProAsync = ref.watch(proStatusProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkPilot Pro'),
      ),
      body: isProAsync.when(
        data: (isPro) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero Status Card
            Card(
              color: isPro ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      isPro ? Icons.verified : Icons.workspace_premium_outlined,
                      size: 56,
                      color: isPro ? theme.colorScheme.primary : theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPro ? 'LinkPilot Pro Active' : 'Upgrade to LinkPilot Pro',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isPro
                          ? 'Thank you for supporting private, default-browser routing. All Pro features are permanently unlocked.'
                          : 'One-time unlock for power users. No subscriptions, no ads, completely offline.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isPro ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Feature Comparison',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildFeatureRow(
              context,
              title: 'Saved Routing Rules',
              freeDesc: 'Up to 5 rules',
              proDesc: 'Unlimited rules',
              isPro: isPro,
            ),
            _buildFeatureRow(
              context,
              title: 'Source App Rules',
              freeDesc: 'Excluded',
              proDesc: 'Full support (Reddit, X, etc.)',
              isPro: isPro,
            ),
            _buildFeatureRow(
              context,
              title: 'Private Mode Routing',
              freeDesc: 'Picker only',
              proDesc: 'Automated by rule',
              isPro: isPro,
            ),
            _buildFeatureRow(
              context,
              title: 'Backup & Restore',
              freeDesc: 'Manual only',
              proDesc: 'Full JSON Import & Export',
              isPro: isPro,
            ),
            _buildFeatureRow(
              context,
              title: 'Tracker Cleaning',
              freeDesc: 'Standard (bundled rules)',
              proDesc: 'Standard + Aggressive',
              isPro: isPro,
            ),

            const SizedBox(height: 32),

            // Action Button
            if (!isPro)
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(proStatusProvider.notifier).setUnlocked(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('LinkPilot Pro successfully unlocked!')),
                    );
                  }
                },
                icon: const Icon(Icons.star),
                label: const Text('Unlock Pro (One-Time Purchase)'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(proStatusProvider.notifier).setUnlocked(false);
                },
                icon: const Icon(Icons.restore),
                label: const Text('Revert to Free Tier (Tester Option)'),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required String title,
    required String freeDesc,
    required String proDesc,
    required bool isPro,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isPro ? proDesc : 'Free: $freeDesc • Pro: $proDesc',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
