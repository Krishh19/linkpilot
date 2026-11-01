import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linkpilot/data/linkpilot_providers.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';
import 'package:linkpilot/generated/linkpilot_api.g.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(browserSetupStatusProvider);
      ref.invalidate(installedBrowsersProvider);
      // The native router writes rules/history/usage while this UI is backgrounded.
      ref.invalidate(rulesProvider);
      ref.invalidate(historyProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupAsync = ref.watch(browserSetupStatusProvider);
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
          ref.invalidate(browserSetupStatusProvider);
          ref.invalidate(installedBrowsersProvider);
          ref.invalidate(rulesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Default Browser Status Banner
            setupAsync.when(
              data: (status) => _buildStatusCard(context, ref, status),
              loading: () => _buildStatusCard(context, ref, null),
              error: (_, __) => _buildStatusErrorCard(context, ref),
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
                                color: theme.colorScheme.onPrimaryContainer
                                    .withAlpha(200),
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
                      data: (rules) =>
                          '${rules.where((r) => r.enabled).length} active',
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
                    title: 'About',
                    subtitle: 'Privacy & open source',
                    icon: Icons.info_outline,
                    onTap: () => context.push('/about'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref,
    BrowserSetupStatusPigeon? status,
  ) {
    final theme = Theme.of(context);

    if (status == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Checking Android browser settings…',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final isReady = status.roleHeld && status.isLinkPilotHandler;
    final handlerName =
        status.currentHandlerLabel ??
        status.currentHandlerPackage ??
        'another app';
    final color = isReady ? Colors.green : Colors.orange;
    final title = isReady
        ? 'LinkPilot is your Default Browser'
        : status.roleHeld
        ? 'Android is still sending links to $handlerName'
        : "LinkPilot is not Android's Default Browser";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isReady ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 12),
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
                      Text(
                        isReady
                            ? 'Every tapped web link is routed through LinkPilot.'
                            : 'Android sends tapped links to $handlerName. LinkPilot never sees them, so Reddit and other apps open it directly.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isReady) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.open_in_browser,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Android currently opens web links in',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            status.currentHandlerPackage == null
                                ? handlerName
                                : '$handlerName (${status.currentHandlerPackage})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!status.qualifiesForBrowserRole) ...[
              const SizedBox(height: 8),
              _buildDiagnosticRow(
                context,
                icon: Icons.error_outline,
                color: Colors.red,
                text: 'LinkPilot is not registered to handle web links in this build. Reinstall the app.',
              ),
            ],
            if (status.roleHeld && !status.customTabsReady) ...[
              const SizedBox(height: 8),
              _buildDiagnosticRow(
                context,
                icon: Icons.extension_off,
                color: Colors.orange,
                text: 'Custom Tabs service not detected. Apps like Reddit may hand links to Chrome instead.',
              ),
            ],
            if (!status.roleAvailable && !status.roleHeld) ...[
              const SizedBox(height: 8),
              Text(
                'This Android version cannot show the default-browser dialog from inside the app. Open Settings → Apps → Default apps → Browser app and choose LinkPilot.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (!isReady) ...[
              const SizedBox(height: 12),
              if (!status.roleHeld) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _requestDefaultBrowserRole(context, ref),
                    child: const Text('Set LinkPilot as Default'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openDefaultAppsSettings(context, ref),
                  child: const Text('Open Android Default Apps'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Android won't let you change it? Share the link from Reddit and pick LinkPilot.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (!status.customTabsReady) ...[
              const SizedBox(height: 8),
              Text(
                'Some apps that use Custom Tabs may still open Chrome. Share the link to LinkPilot instead.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusErrorCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Could not read Android browser settings.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(browserSetupStatusProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Future<void> _requestDefaultBrowserRole(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final launched = await ref
        .read(linkPilotRepositoryProvider)
        .requestDefaultBrowserRole();
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the default browser settings. Open Settings > Apps > Default apps.',
          ),
        ),
      );
    }
    ref.invalidate(browserSetupStatusProvider);
    ref.invalidate(installedBrowsersProvider);
  }

  Future<void> _openDefaultAppsSettings(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final opened = await ref
        .read(linkPilotRepositoryProvider)
        .openDefaultAppsSettings();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open Android settings. Open Settings > Apps > Default apps.',
          ),
        ),
      );
    }
    ref.invalidate(browserSetupStatusProvider);
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
