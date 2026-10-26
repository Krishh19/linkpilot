import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linkpilot/data/linkpilot_providers.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDefaultAsync = ref.watch(defaultBrowserStatusProvider);
    final browsersAsync = ref.watch(installedBrowsersProvider);
    final rulesAsync = ref.watch(rulesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LinkPilot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'In-app browser help & limits',
            onPressed: () => context.push('/help'),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About & Privacy',
            onPressed: () => context.push('/about'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(defaultBrowserStatusProvider);
          ref.invalidate(installedBrowsersProvider);
          ref.invalidate(rulesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Default Browser Status Banner
            isDefaultAsync.when(
              data: (isDefault) => _buildStatusCard(context, ref, isDefault),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => _buildStatusCard(context, ref, false),
            ),

            const SizedBox(height: 16),

            // Live Router Test Quick Action
            Card(
              color: theme.colorScheme.primaryContainer,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/test-url'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test URL Routing',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Test any link against the native Kotlin engine and see what gets cleaned.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Hub Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Rules',
                    subtitle: rulesAsync.when(
                      data: (rules) => '${rules.where((r) => r.enabled).length} active',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.alt_route,
                    onTap: () => context.push('/rules'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Browsers',
                    subtitle: browsersAsync.when(
                      data: (b) => '${b.length} detected',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.open_in_browser,
                    onTap: () => context.push('/browsers'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Cleaner',
                    subtitle: 'Trackers & unwrapping',
                    icon: Icons.cleaning_services_outlined,
                    onTap: () => context.push('/cleaner'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'History',
                    subtitle: 'Opt-in routed links',
                    icon: Icons.history,
                    onTap: () => context.push('/history'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Backup',
                    subtitle: 'Export & restore JSON',
                    icon: Icons.backup_outlined,
                    onTap: () => context.push('/backup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Pro',
                    subtitle: 'Unlimited & offline',
                    icon: Icons.workspace_premium_outlined,
                    onTap: () => context.push('/pro'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, WidgetRef ref, bool isDefault) {
    final theme = Theme.of(context);
    final color = isDefault ? Colors.green : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDefault ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDefault ? 'LinkPilot is your Default Browser' : 'Default Browser Not Set',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isDefault
                            ? 'Every tapped link passes through LinkPilot instantly.'
                            : 'Set LinkPilot as default to intercept and route links.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isDefault) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final repo = ref.read(linkPilotRepositoryProvider);
                    await repo.requestDefaultBrowserRole();
                    ref.invalidate(defaultBrowserStatusProvider);
                  },
                  child: const Text('Set as Default Browser'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
