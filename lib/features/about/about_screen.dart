import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.alt_route, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'LinkPilot',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Version 1.0.0 (Native Router + Flutter Shell)',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Privacy Manifesto',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. No INTERNET Permission: LinkPilot has no capability to connect to the internet in release builds.\n'
            '2. Zero Tracking: No analytics, telemetry, or crash reporters.\n'
            '3. URL Confidentiality: Your URLs, history, and referrer source apps are never logged, stored remotely, or transmitted.\n'
            '4. Pure Native Speed: Routing happens entirely in native Kotlin before Flutter ever starts, ensuring sub-150ms link handling.\n'
            '5. Offline Cleaner: All redirect unravelling and parameter stripping operates 100% locally on device.',
            style: TextStyle(height: 1.8),
          ),

          const SizedBox(height: 24),

          Text(
            'Open Source & Licenses',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'LinkPilot is built using Flutter, Dart, Kotlin, Jetpack Compose, kotlinx.serialization, and Pigeon.',
          ),
        ],
      ),
    );
  }
}
