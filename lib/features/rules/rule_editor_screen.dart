import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linkpilot/data/linkpilot_providers.dart';
import 'package:linkpilot/generated/linkpilot_api.g.dart';
import 'package:uuid/uuid.dart';

class RuleEditorScreen extends ConsumerStatefulWidget {
  const RuleEditorScreen({super.key, this.ruleId});

  final String? ruleId;

  @override
  ConsumerState<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends ConsumerState<RuleEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priorityController;
  late TextEditingController _domainInputController;
  late TextEditingController _sourceInputController;
  late TextEditingController _regexController;

  final List<String> _domains = [];
  final List<String> _sources = [];

  String _actionType = 'browser'; // browser, app, ask
  String? _targetPackage;
  String _mode = 'NORMAL'; // NORMAL, PRIVATE
  bool _enabled = true;
  int _createdAt = 0;
  int _hitCount = 0;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priorityController = TextEditingController(text: '10');
    _domainInputController = TextEditingController();
    _sourceInputController = TextEditingController();
    _regexController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priorityController.dispose();
    _domainInputController.dispose();
    _sourceInputController.dispose();
    _regexController.dispose();
    super.dispose();
  }

  void _initFromRule(RulePigeon rule) {
    if (_initialized) return;
    _initialized = true;

    _nameController.text = rule.name ?? '';
    _priorityController.text = rule.priority.toString();
    _regexController.text = rule.urlRegex ?? '';
    _domains.addAll(rule.domains);
    _sources.addAll(rule.sourcePackages);
    _actionType = rule.actionType;
    _targetPackage = rule.targetPackage;
    _mode = rule.mode ?? 'NORMAL';
    _enabled = rule.enabled;
    _createdAt = rule.createdAtEpochMs;
    _hitCount = rule.hitCount;
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(rulesProvider);
    final browsersAsync = ref.watch(installedBrowsersProvider);
    final theme = Theme.of(context);

    // If editing existing rule, initialize once
    if (widget.ruleId != null && !_initialized) {
      rulesAsync.whenData((rules) {
        final existing = rules.where((r) => r.id == widget.ruleId).firstOrNull;
        if (existing != null) {
          _initFromRule(existing);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ruleId == null ? 'Create Rule' : 'Edit Rule'),
        actions: [
          if (widget.ruleId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Rule',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Rule Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Rule Name (Optional)',
                hintText: 'e.g. Reddit in Firefox, Work links',
              ),
            ),

            const SizedBox(height: 16),

            // Priority
            TextFormField(
              controller: _priorityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Numeric Priority',
                hintText: 'Higher numbers win (e.g. 100 > 10)',
                helperText: 'Ties break automatically by specificity: Regex > Exact > Wildcard > Source',
              ),
              validator: (val) {
                if (val == null || val.isEmpty || int.tryParse(val) == null) {
                  return 'Enter a valid integer priority';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Condition: Target Domains
            Text(
              'Domain Condition',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Match exact domain (e.g. reddit.com) or wildcards (e.g. *.reddit.com)',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _domainInputController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. *.reddit.com',
                      isDense: true,
                    ),
                    onSubmitted: _addDomain,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => _addDomain(_domainInputController.text),
                  child: const Text('Add'),
                ),
              ],
            ),

            if (_domains.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _domains.map((d) {
                  return Chip(
                    label: Text(d),
                    onDeleted: () => setState(() => _domains.remove(d)),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Condition: Source Packages
            Text(
              'Source App Condition (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Only match links opened from specific apps (e.g. com.reddit.frontpage)',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sourceInputController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. com.twitter.android',
                      isDense: true,
                    ),
                    onSubmitted: _addSource,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => _addSource(_sourceInputController.text),
                  child: const Text('Add'),
                ),
              ],
            ),

            if (_sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _sources.map((s) {
                  return Chip(
                    avatar: const Icon(Icons.source, size: 16),
                    label: Text(s),
                    onDeleted: () => setState(() => _sources.remove(s)),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Condition: URL Regex
            Text(
              'URL Regex Pattern (Optional, Advanced)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regexController,
              decoration: const InputDecoration(
                hintText: 'e.g. https://github\\.com/[^/]+/[^/]+/issues/.*',
                helperText: 'Guarded by step counter to prevent ReDoS hangs.',
              ),
            ),

            const SizedBox(height: 24),

            // Action: What to do
            Text(
              'Action',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'browser', label: Text('Browser'), icon: Icon(Icons.open_in_browser)),
                ButtonSegment(value: 'app', label: Text('Native App'), icon: Icon(Icons.apps)),
                ButtonSegment(value: 'ask', label: Text('Always Ask'), icon: Icon(Icons.help_outline)),
              ],
              selected: {_actionType},
              onSelectionChanged: (val) {
                setState(() => _actionType = val.first);
              },
            ),

            const SizedBox(height: 16),

            if (_actionType == 'browser') ...[
              browsersAsync.when(
                data: (browsers) {
                  if (browsers.isEmpty) {
                    return const Text('No installed browsers detected');
                  }
                  final currentTarget = _targetPackage ?? browsers.first.packageName;
                  return DropdownButtonFormField<String>(
                    initialValue: browsers.any((b) => b.packageName == currentTarget)
                        ? currentTarget
                        : browsers.first.packageName,
                    decoration: const InputDecoration(labelText: 'Target Browser'),
                    items: browsers.map((b) {
                      return DropdownMenuItem(
                        value: b.packageName,
                        child: Text('${b.label} (${b.packageName})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _targetPackage = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Normal'),
                      value: 'NORMAL',
                      groupValue: _mode,
                      onChanged: (val) => setState(() => _mode = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Private Tab'),
                      value: 'PRIVATE',
                      groupValue: _mode,
                      onChanged: (val) => setState(() => _mode = val!),
                    ),
                  ),
                ],
              ),
            ] else if (_actionType == 'app') ...[
              TextFormField(
                initialValue: _targetPackage,
                decoration: const InputDecoration(
                  labelText: 'Target App Package Name',
                  hintText: 'e.g. com.reddit.frontpage',
                ),
                onChanged: (val) => _targetPackage = val.trim(),
                validator: (val) => val == null || val.isEmpty ? 'Package required' : null,
              ),
            ],

            const SizedBox(height: 32),

            // Save Button
            FilledButton(
              onPressed: _saveRule,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(widget.ruleId == null ? 'Create Rule' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDomain(String val) {
    final trimmed = val.trim().toLowerCase();
    if (trimmed.isNotEmpty && !_domains.contains(trimmed)) {
      setState(() {
        _domains.add(trimmed);
        _domainInputController.clear();
      });
    }
  }

  void _addSource(String val) {
    final trimmed = val.trim().toLowerCase();
    if (trimmed.isNotEmpty && !_sources.contains(trimmed)) {
      setState(() {
        _sources.add(trimmed);
        _sourceInputController.clear();
      });
    }
  }

  Future<void> _saveRule() async {
    if (!_formKey.currentState!.validate()) return;

    if (_domains.isEmpty && _sources.isEmpty && _regexController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one domain, source app, or URL regex')),
      );
      return;
    }

    final priority = int.tryParse(_priorityController.text) ?? 10;
    final regex = _regexController.text.trim().isNotEmpty ? _regexController.text.trim() : null;

    final rule = RulePigeon(
      id: widget.ruleId ?? const Uuid().v4(),
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      enabled: _enabled,
      priority: priority,
      domains: _domains,
      urlRegex: regex,
      sourcePackages: _sources,
      actionType: _actionType,
      targetPackage: _targetPackage,
      mode: _mode,
      createdAtEpochMs: _createdAt == 0 ? DateTime.now().millisecondsSinceEpoch : _createdAt,
      hitCount: _hitCount,
    );

    if (widget.ruleId == null) {
      await ref.read(rulesProvider.notifier).addRule(rule);
    } else {
      await ref.read(rulesProvider.notifier).updateRule(rule);
    }

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rule?'),
        content: const Text('Are you sure you want to delete this routing rule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.ruleId != null) {
      await ref.read(rulesProvider.notifier).deleteRule(widget.ruleId!);
      if (mounted) context.pop();
    }
  }
}
