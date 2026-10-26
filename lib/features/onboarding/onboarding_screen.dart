import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linkpilot/data/linkpilot_providers.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup LinkPilot'),
        actions: [
          if (_currentPage < 3)
            TextButton(
              onPressed: () => context.go('/'),
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
                _buildStep2(context),
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
                        color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
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
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'LinkPilot is a link router that never renders a web page. Every tapped link is cleaned of trackers and sent instantly to the browser of your choice.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    final theme = Theme.of(context);
    final isDefault = ref.watch(defaultBrowserStatusProvider).value ?? false;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          Icon(
            isDefault ? Icons.check_circle : Icons.public,
            size: 84,
            color: isDefault ? Colors.green : theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            isDefault ? 'Default Browser Set!' : 'Set as Default Browser',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Android lets only one app be the default browser. Set LinkPilot as your default browser so it can intercept and direct links.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!isDefault)
            FilledButton.icon(
              onPressed: () async {
                final repo = ref.read(linkPilotRepositoryProvider);
                await repo.requestDefaultBrowserRole();
                ref.invalidate(defaultBrowserStatusProvider);
              },
              icon: const Icon(Icons.settings),
              label: const Text('Set LinkPilot as Default'),
            )
          else
            const Text('All set! LinkPilot is ready to receive links.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          const Spacer(),
        ],
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
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'If no rule matches, links open in this browser (or in the instant picker if none chosen).',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                        ref.read(settingsProvider.notifier).setGlobalDefault(null);
                      },
                    ),
                    for (final b in browsers)
                      RadioListTile<String?>(
                        title: Text(b.label),
                        subtitle: Text(b.packageName, style: const TextStyle(fontSize: 12)),
                        value: b.packageName,
                        groupValue: settings?.globalDefaultBrowser,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).setGlobalDefault(val);
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
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
