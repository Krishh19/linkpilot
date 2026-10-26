import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';
import 'package:linkpilot/generated/linkpilot_api.g.dart';

class TestUrlScreen extends ConsumerStatefulWidget {
  const TestUrlScreen({super.key});

  @override
  ConsumerState<TestUrlScreen> createState() => _TestUrlScreenState();
}

class _TestUrlScreenState extends ConsumerState<TestUrlScreen> {
  final _urlController = TextEditingController(
    text: 'https://old.reddit.com/r/android?utm_source=twitter&utm_medium=social',
  );
  final _sourceController = TextEditingController();

  RoutingResultPigeon? _result;
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _evaluateRoute() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isLoading = true);
    final repo = ref.read(linkPilotRepositoryProvider);
    final source = _sourceController.text.trim().isNotEmpty ? _sourceController.text.trim() : null;

    try {
      final res = await repo.testRouteUrl(url, sourcePackage: source);
      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error testing URL: $e')),
        );
      }
    }
  }

  void _applyPreset(String url, [String? source]) {
    _urlController.text = url;
    if (source != null) {
      _sourceController.text = source;
    } else {
      _sourceController.clear();
    }
    _evaluateRoute();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test URL Routing'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Test URL Against Native Engine',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Evaluates trackers, redirect unwrapping, and rules using the exact native Kotlin engine.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 16),

          // URL Input
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL to test',
              hintText: 'https://example.com/page?utm_source=...',
              prefixIcon: Icon(Icons.link),
            ),
          ),

          const SizedBox(height: 12),

          // Source Package Input
          TextField(
            controller: _sourceController,
            decoration: const InputDecoration(
              labelText: 'Simulated Source App (Optional)',
              hintText: 'e.g. com.reddit.frontpage',
              prefixIcon: Icon(Icons.source),
            ),
          ),

          const SizedBox(height: 12),

          // Presets
          Text(
            'Quick Presets:',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ActionChip(
                label: const Text('Reddit with UTM'),
                onPressed: () => _applyPreset('https://old.reddit.com/r/android?utm_source=twitter&fbclid=123'),
              ),
              ActionChip(
                label: const Text('FB Linkshim'),
                onPressed: () => _applyPreset('https://l.facebook.com/l.php?u=https%3A%2F%2Fgithub.com%2Fflutter%2Fflutter%3Futm_medium%3Dsocial'),
              ),
              ActionChip(
                label: const Text('YouTube Timestamp'),
                onPressed: () => _applyPreset('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s&si=junkTracking'),
              ),
              ActionChip(
                label: const Text('Twitter Share'),
                onPressed: () => _applyPreset('https://x.com/flutterdev/status/123456?s=20'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Run Evaluation Button
          FilledButton.icon(
            onPressed: _isLoading ? null : _evaluateRoute,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: const Text('Evaluate Route'),
          ),

          const SizedBox(height: 24),

          // Result Card
          if (_result != null) _buildResultCard(context, _result!),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, RoutingResultPigeon res) {
    final theme = Theme.of(context);
    final isLaunch = res.decisionType == 'launch';

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLaunch ? Icons.launch : Icons.touch_app,
                  color: isLaunch ? Colors.green : Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLaunch ? 'Decision: Direct Launch' : 'Decision: Show Picker Sheet',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isLaunch
                            ? 'Target: ${res.targetPackage} (${res.mode ?? 'NORMAL'})'
                            : 'Reason: ${res.pickerReason ?? 'No rule matched'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isLaunch ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            if (res.matchedRuleName != null || res.matchedRuleId != null) ...[
              _buildInfoRow('Matched Rule', res.matchedRuleName ?? res.matchedRuleId!),
              const SizedBox(height: 8),
            ],

            _buildInfoRow('Original URL', res.originalUrl),
            const SizedBox(height: 8),
            _buildInfoRow('Cleaned URL', res.cleanedUrl),

            if (res.removedParams.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Trackers Cleaned (${res.removedParams.length}):',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: res.removedParams.map((p) {
                  return Chip(
                    backgroundColor: theme.colorScheme.errorContainer,
                    label: Text(p, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            if (isLaunch && res.targetPackage != null)
              OutlinedButton.icon(
                onPressed: () {
                  final repo = ref.read(linkPilotRepositoryProvider);
                  repo.openInBrowser(
                    res.cleanedUrl,
                    res.targetPackage!,
                    mode: res.mode ?? 'NORMAL',
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: Text('Open in ${res.targetPackage} Now'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        SelectableText(
          value,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
