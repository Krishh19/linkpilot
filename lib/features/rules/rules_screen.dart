import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linkpilot/data/linkpilot_providers.dart';
import 'package:linkpilot/generated/linkpilot_api.g.dart';

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(rulesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routing Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Test URL routing',
            onPressed: () => context.push('/test-url'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search rules by domain, package, or name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Rules List
          Expanded(
            child: rulesAsync.when(
              data: (rules) {
                final filtered = rules.where((r) {
                  if (_searchQuery.isEmpty) return true;
                  final nameMatch = r.name?.toLowerCase().contains(_searchQuery) ?? false;
                  final domainMatch = r.domains.any((d) => d.toLowerCase().contains(_searchQuery));
                  final sourceMatch = r.sourcePackages.any((s) => s.toLowerCase().contains(_searchQuery));
                  final pkgMatch = r.targetPackage?.toLowerCase().contains(_searchQuery) ?? false;
                  return nameMatch || domainMatch || sourceMatch || pkgMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.alt_route,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          rules.isEmpty ? 'No routing rules created yet' : 'No matching rules found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rules.isEmpty
                              ? 'Tap + below or pick "Always" in the picker to save rules.'
                              : 'Try searching with another keyword.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final rule = filtered[index];
                    return _buildRuleCard(context, rule);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading rules: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final isPro = ref.read(proStatusProvider).value ?? false;
          final ruleCount = rulesAsync.value?.length ?? 0;

          if (!isPro && ruleCount >= 5) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Free Tier Limit (5 Rules)'),
                content: const Text(
                  'The free tier includes up to 5 routing rules. Upgrade to LinkPilot Pro for unlimited rules, source-app rules, and automated private tabs.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Later'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/pro');
                    },
                    child: const Text('View Pro'),
                  ),
                ],
              ),
            );
            return;
          }

          context.push('/rules/new');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
    );
  }

  Widget _buildRuleCard(BuildContext context, RulePigeon rule) {
    final theme = Theme.of(context);

    final title = rule.name?.isNotEmpty == true
        ? rule.name!
        : (rule.domains.isNotEmpty
            ? rule.domains.join(', ')
            : (rule.sourcePackages.isNotEmpty
                ? 'From ${rule.sourcePackages.join(', ')}'
                : 'Rule #${rule.id.length >= 6 ? rule.id.substring(0, 6) : rule.id}'));

    final actionDescription = switch (rule.actionType) {
      'browser' => 'Open in ${rule.targetPackage ?? 'Browser'}${rule.mode == 'PRIVATE' ? ' (Private)' : ''}',
      'app' => 'Open in app: ${rule.targetPackage}',
      'ask' => 'Always ask (show picker)',
      _ => 'Unknown action',
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push('/rules/edit/${rule.id}'),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: rule.enabled ? null : TextDecoration.lineThrough,
                  color: rule.enabled ? theme.colorScheme.onSurface : theme.colorScheme.outline,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'P${rule.priority}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              actionDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final domain in rule.domains)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(domain),
                    labelStyle: theme.textTheme.labelSmall,
                    padding: EdgeInsets.zero,
                  ),
                for (final source in rule.sourcePackages)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.source, size: 14),
                    label: Text(source),
                    labelStyle: theme.textTheme.labelSmall,
                    padding: EdgeInsets.zero,
                  ),
                if (rule.urlRegex != null && rule.urlRegex!.isNotEmpty)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.code, size: 14),
                    label: const Text('Regex'),
                    labelStyle: theme.textTheme.labelSmall,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        trailing: Switch(
          value: rule.enabled,
          onChanged: (_) {
            ref.read(rulesProvider.notifier).toggleRule(rule.id);
          },
        ),
      ),
    );
  }
}
