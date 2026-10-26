import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkpilot/data/linkpilot_providers.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatTimestamp(int epochMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final historyAsync = ref.watch(historyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routing History'),
        actions: [
          historyAsync.when(
            data: (items) => items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Clear all history',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear all history?'),
                          content: const Text('This will delete all logged links locally. This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear All')),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(historyProvider.notifier).clearHistory();
                      }
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (!settings.historyEnabled) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_toggle_off, size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'History is Disabled',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LinkPilot never logs URLs by default. If you choose to enable history, links will be stored purely offline on your device with auto-purge.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Enable Routing History'),
                      onPressed: () async {
                        settings.historyEnabled = true;
                        await ref.read(settingsProvider.notifier).updateSettings(settings);
                        ref.invalidate(historyProvider);
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Retention Settings Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Retention: ${settings.historyRetentionDays} days',
                      style: theme.textTheme.labelMedium,
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () async {
                            final days = await showDialog<int>(
                              context: context,
                              builder: (ctx) => SimpleDialog(
                                title: const Text('Select Retention Period'),
                                children: [1, 7, 30].map((d) {
                                  return SimpleDialogOption(
                                    onPressed: () => Navigator.pop(ctx, d),
                                    child: Text('$d day${d > 1 ? 's' : ''}'),
                                  );
                                }).toList(),
                              ),
                            );
                            if (days != null) {
                              settings.historyRetentionDays = days;
                              await ref.read(settingsProvider.notifier).updateSettings(settings);
                              ref.invalidate(historyProvider);
                            }
                          },
                          child: const Text('Change'),
                        ),
                        TextButton(
                          onPressed: () async {
                            settings.historyEnabled = false;
                            await ref.read(settingsProvider.notifier).updateSettings(settings);
                          },
                          child: const Text('Turn Off', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // History Items List
              Expanded(
                child: historyAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('No routed links in history yet.'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.link, color: theme.colorScheme.onPrimaryContainer),
                          ),
                          title: Text(
                            item.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Opened in ${item.targetPackage} • ${_formatTimestamp(item.timestampEpochMs)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) async {
                              if (val == 'open') {
                                final repo = ref.read(linkPilotRepositoryProvider);
                                await repo.openInBrowser(item.url, item.targetPackage);
                              } else if (val == 'copy') {
                                await Clipboard.setData(ClipboardData(text: item.url));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied to clipboard')),
                                  );
                                }
                              } else if (val == 'delete') {
                                await ref.read(historyProvider.notifier).deleteItem(item.id);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'open', child: Text('Reopen')),
                              const PopupMenuItem(value: 'copy', child: Text('Copy URL')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading history: $e')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading settings: $e')),
      ),
    );
  }
}
