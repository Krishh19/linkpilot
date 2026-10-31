import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linkpilot/data/linkpilot_providers.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';
import 'package:linkpilot/generated/linkpilot_api.g.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(browserSetupStatusProvider);
    }
  }

  Future<void> _completeOnboarding() async {
    if (_finishing) return;
    _finishing = true;
    try {
      await ref.read(linkPilotRepositoryProvider).setOnboardingCompleted(true);
    } catch (_) {
      // Never trap the user in onboarding if persistence fails.
    }
    if (mounted) {
      context.go('/');
    } else {
      _finishing = false;
    }
  }

  Future<void> _nextPage() async {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    final status = ref.read(browserSetupStatusProvider).value;
    final isReady =
        status != null && status.roleHeld && status.isLinkPilotHandler;
    if (status != null && !isReady) {
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("LinkPilot can't receive links yet"),
          content: Text(
            'Android is sending web links to ${status.currentHandlerLabel ?? 'your current browser'}. '
            'Until LinkPilot is the default browser, tapped links in Reddit and other apps will bypass it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('finish'),
              child: const Text('Finish anyway'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop('setDefault'),
              child: const Text('Set as default'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == 'setDefault') {
        await _requestDefaultBrowserRole();
        return;
      }
      if (choice != 'finish') return;
    }
    await _completeOnboarding();
  }

  Future<void> _requestDefaultBrowserRole() async {
    final launched = await ref
        .read(linkPilotRepositoryProvider)
        .requestDefaultBrowserRole();
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the default browser settings. Open Settings > Apps > Default apps.',
          ),
        ),
      );
    }
    ref.invalidate(browserSetupStatusProvider);
  }

  Future<void> _openDefaultAppsSettings() async {
    final opened = await ref
        .read(linkPilotRepositoryProvider)
        .openDefaultAppsSettings();
    if (!opened && mounted) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final setupAsync = ref.watch(browserSetupStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup LinkPilot'),
        actions: [
          if (_currentPage < 3)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildStep1(context),
                _buildStep2(context, setupAsync.value),
                _buildStep3(context),
                _buildStep4(context),
              ],
            ),
          ),
          // Page Indicators and Next Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(4, (index) {
                    final isActive = (index == _currentPage);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                FilledButton(
                  onPressed: _nextPage,
                  child: Text(_currentPage == 3 ? 'Get Started' : 'Continue'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          Icon(Icons.alt_route, size: 84, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Smart Link Routing',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'LinkPilot is a link router that never renders a web page. Every tapped link is cleaned of trackers and sent instantly to the browser of your choice.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context, BrowserSetupStatusPigeon? status) {
    final theme = Theme.of(context);
    final isReady =
        status != null && status.roleHeld && status.isLinkPilotHandler;
    final handlerName =
        status?.currentHandlerLabel ??
        status?.currentHandlerPackage ??
        'your current browser';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReady ? Icons.check_circle : Icons.public,
              size: 84,
              color: isReady ? Colors.green : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              isReady ? 'Default Browser Set!' : 'Set as Default Browser',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isReady
                  ? 'LinkPilot now receives every tapped web link.'
                  : 'Android sends web links to $handlerName. LinkPilot must be the default browser to intercept and route them.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (status != null && !isReady) ...[
              const SizedBox(height: 16),
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
              if (!status.qualifiesForBrowserRole) ...[
                const SizedBox(height: 8),
                Text(
                  'LinkPilot is not registered to handle web links in this build. Reinstall the app.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              if (!status.roleAvailable && !status.roleHeld) ...[
                const SizedBox(height: 8),
                Text(
                  'This Android version cannot show the default-browser dialog from inside the app. Open Settings → Apps → Default apps → Browser app and choose LinkPilot.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
            const SizedBox(height: 24),
            if (isReady)
              Text(
                status.customTabsReady
                    ? 'All set! LinkPilot is ready to receive links.'
                    : 'LinkPilot is the default browser, but its Custom Tabs service is missing. Some apps may still open Chrome.',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
            else ...[
              if (status?.roleHeld != true)
                FilledButton.icon(
                  onPressed: _requestDefaultBrowserRole,
                  icon: const Icon(Icons.settings),
                  label: const Text('Set LinkPilot as Default'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _openDefaultAppsSettings,
                child: const Text('Open Android Default Apps'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep3(BuildContext context) {
    final theme = Theme.of(context);
    final browsersAsync = ref.watch(installedBrowsersProvider);
    final settings = ref.watch(settingsProvider).value;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'Choose Fallback Browser',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'If no rule matches, links open in this browser (or in the instant picker if none chosen).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: browsersAsync.when(
              data: (browsers) {
                return ListView(
                  children: [
                    RadioListTile<String?>(
                      title: const Text('Always show quick picker'),
                      value: null,
                      groupValue: settings?.globalDefaultBrowser,
                      onChanged: (val) {
                        ref
                            .read(settingsProvider.notifier)
                            .setGlobalDefault(null);
                      },
                    ),
                    for (final b in browsers)
                      RadioListTile<String?>(
                        title: Text(b.label),
                        subtitle: Text(
                          b.packageName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: b.packageName,
                        groupValue: settings?.globalDefaultBrowser,
                        onChanged: (val) {
                          ref
                              .read(settingsProvider.notifier)
                              .setGlobalDefault(val);
                        },
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          Icon(Icons.shield_outlined, size: 84, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Private by Design',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '• No INTERNET permission\n• No analytics or crash SDKs\n• URLs are never saved or sent anywhere\n• All rules and cleaning happen 100% on device',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
