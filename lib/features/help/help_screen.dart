import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & App Guides')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bypass In-App Browsers',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Apps like Reddit, X, and Facebook open links in their own trapped in-app browser by default. Follow these steps to send links directly to LinkPilot:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          _buildAppGuide(
            context,
            app: 'Reddit',
            instructions: 'Tap your profile icon -> Settings -> Open links -> "Default browser" (if your version shows it). Recent Reddit Android builds often ignore this and force their in-app browser. If a link still opens in Chrome, tap Share -> LinkPilot instead.',
          ),

          _buildAppGuide(
            context,
            app: 'X (Twitter)',
            instructions: 'Settings and privacy -> Accessibility, display, and languages -> Display -> Turn off "Use in-app browser".',
          ),

          _buildAppGuide(
            context,
            app: 'Instagram',
            instructions: 'Settings -> Your activity -> Links you\'ve visited -> Options -> Open in external browser (or use the share sheet).',
          ),

          _buildAppGuide(
            context,
            app: 'Facebook',
            instructions: 'Settings & Privacy -> Settings -> Media -> Turn on "Links open externally".',
          ),

          _buildAppGuide(
            context,
            app: 'Telegram',
            instructions:
                'Settings -> Chat Settings -> Turn off "In-App Browser".',
          ),

          _buildAppGuide(
            context,
            app: 'LinkedIn',
            instructions: 'Settings -> Account preferences -> Turn off "Open links in app".',
          ),

          const SizedBox(height: 24),

          // Platform Constraints Card
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Platform Limits (Honesty Policy)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Hard-coded WebViews: Apps that render WebViews internally without firing an intent cannot be intercepted automatically without invasive Accessibility Services, which LinkPilot refuses to use for your security. Use the Android Share button -> LinkPilot instead.\n\n'
                    '• Custom Tabs apps (e.g. Reddit, Gmail): these hand links to the default browser. LinkPilot advertises a Custom Tabs service, but it only receives them while LinkPilot is set as your default browser. Some apps, including recent Reddit builds, pin Chrome or use a WebView even when LinkPilot is default. There is no safe automatic workaround; use Share -> LinkPilot for those links.\n\n'
                    '• Verified Android App Links: Domains claimed and cryptographically verified by native apps (e.g. youtube.com) open in their respective app directly before reaching any browser.\n\n'
                    '• Verify setup: the Home tab shows the app Android currently resolves for web links. It must say LinkPilot before tapped links can be intercepted.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppGuide(
    BuildContext context, {
    required String app,
    required String instructions,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(instructions, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
