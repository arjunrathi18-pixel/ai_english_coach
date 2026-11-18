import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_providers.dart';
import 'anthropic_client.dart';
import 'api_key_store.dart';
import 'design_tokens.dart';
import 'ui_components.dart';
import 'zero_cost_policy.dart';

/// Profile > AI Connection — the AI Provider Management screen.
/// Shows only real data: what is saved, what the policy allows, and what
/// THIS app has counted. No fake usage or connection numbers.
class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final Map<String, TextEditingController> _keyCtl = {
    for (final p in kAiProviders) p.id: TextEditingController(),
  };
  final Map<String, TextEditingController> _modelCtl = {
    for (final p in kAiProviders) p.id: TextEditingController(),
  };
  final Map<String, bool> _busy = {};
  final Map<String, String?> _result = {}; // '' = ok, text = problem

  List<ProviderStatus> _statuses = [];
  List<String> _priority = [];
  Set<String> _userModels = {};
  bool _zeroCostOnly = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    for (final c in [..._keyCtl.values, ..._modelCtl.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    final zero = await ApiKeyStore.zeroCostOnly();
    final prio = await ApiKeyStore.priority();
    final models = await ApiKeyStore.userVerifiedModels();
    final st = await AnthropicClient.statuses();
    if (!mounted) return;
    setState(() {
      _zeroCostOnly = zero;
      _priority = prio;
      _userModels = models;
      _statuses = st;
      _loading = false;
    });
  }

  Future<void> _saveAndTest(AiProvider p) async {
    final key = _keyCtl[p.id]!.text.trim();
    if (key.isNotEmpty) {
      await ApiKeyStore.save(p.id, key);
      AnthropicClient.clearRejected(p.id);
      _keyCtl[p.id]!.clear();
    }
    await _test(p);
  }

  Future<void> _test(AiProvider p) async {
    setState(() {
      _busy[p.id] = true;
      _result.remove(p.id);
    });
    final error = await AnthropicClient.testProvider(p.id);
    await _refresh();
    if (!mounted) return;
    setState(() {
      _busy[p.id] = false;
      _result[p.id] = error ?? '';
    });
  }

  Future<void> _move(String id, int delta) async {
    final free = _priority.where((x) => kAiProviders.firstWhere((p) => p.id == x).isFree).toList();
    final i = free.indexOf(id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= free.length) return;
    final tmp = free[i];
    free[i] = free[j];
    free[j] = tmp;
    final paid = _priority.where((x) => !kAiProviders.firstWhere((p) => p.id == x).isFree);
    await ApiKeyStore.setPriority([...free, ...paid]);
    await _refresh();
  }

  Future<void> _setZeroCost(bool v) async {
    if (!v) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Allow paid providers?'),
          content: const Text(
            'Zero-cost-only mode protects you from any charge. If you turn it OFF, an optional paid '
            'provider (Anthropic) can be used as the very LAST fallback, and that can cost real money '
            'on your own account. Free providers are always tried first.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep zero-cost')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Turn OFF')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ApiKeyStore.setZeroCostOnly(v);
    await _refresh();
  }

  Color _stateColor(ProviderState s) {
    switch (s) {
      case ProviderState.ready:
        return AppColors.success;
      case ProviderState.rateLimited:
      case ProviderState.noVerifiedModel:
      case ProviderState.blockedPaid:
        return AppColors.warning;
      case ProviderState.keyRejected:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _stateLabel(ProviderState s) {
    switch (s) {
      case ProviderState.ready:
        return 'Ready';
      case ProviderState.rateLimited:
        return 'Rate-limited';
      case ProviderState.noVerifiedModel:
        return 'Disabled';
      case ProviderState.blockedPaid:
        return 'Blocked (paid)';
      case ProviderState.keyRejected:
        return 'Key rejected';
      case ProviderState.disabledByUser:
        return 'Off';
      case ProviderState.notConfigured:
        return 'No key';
    }
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byId = {for (final s in _statuses) s.provider.id: s};
    final order = [
      ..._priority.where((id) => kAiProviders.firstWhere((p) => p.id == id).isFree),
      ..._priority.where((id) => !kAiProviders.firstWhere((p) => p.id == id).isFree),
    ];
    final anyReady = _statuses.any((s) => s.state == ProviderState.ready);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Connection')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Text(
                    'Maximum authorized API spending: \$0.00. Free providers are tried first, in the order below. '
                    'Only models verified as free are ever used. If every free service is unavailable the app '
                    'switches to Offline mode instead of spending money.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Zero-cost-only mode'),
                  subtitle: Text(_zeroCostOnly
                      ? 'ON — paid providers are blocked.'
                      : 'OFF — an optional paid provider may be used as the last fallback.'),
                  value: _zeroCostOnly,
                  onChanged: _setZeroCost,
                ),
                Text(
                  anyReady
                      ? 'Current provider: ${AnthropicClient.lastProviderLabel ?? 'none used yet'}'
                          '${AnthropicClient.lastModel != null ? ' · ${AnthropicClient.lastModel}' : ''}'
                      : 'No free provider is ready.',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  AnthropicClient.lastReplyWasOffline
                      ? 'Offline mode: the last AI request could not be answered, so saved lessons are being used. '
                          'Offline content is not generative AI.'
                      : 'Offline mode: saved lessons and drills always work without internet or AI (they are not generative AI).',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                ...order.map((id) => _providerCard(theme, byId[id])),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Keys are stored only on this phone — never in the app package, the repository or logs. '
                  'Usage numbers are what this app counted itself, not the provider\'s own dashboard. '
                  'Free services have daily limits and may use prompts to improve their models: do not type private information.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
    );
  }

  Widget _providerCard(ThemeData theme, ProviderStatus? s) {
    if (s == null) return const SizedBox.shrink();
    final p = s.provider;
    final color = _stateColor(s.state);
    final canReorder = p.isFree;
    final models = _userModels.where((e) => e.startsWith('${p.id}:')).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: s.state == ProviderState.ready ? AppColors.success : theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (p.isFree ? AppColors.success : AppColors.warning).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(p.isFree ? 'FREE TIER' : 'PAID · OPTIONAL',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              if (canReorder) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Higher priority',
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: () => _move(p.id, -1),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Lower priority',
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  onPressed: () => _move(p.id, 1),
                ),
              ],
            ],
          ),
          Text(p.tagline, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 6),
              Text(_stateLabel(s.state), style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(s.detail, style: theme.textTheme.bodySmall),
          if (s.activeModel != null)
            Text('Active model: ${s.activeModel}', style: theme.textTheme.bodySmall),
          if (s.cooldownUntil != null)
            Text('Available again around ${_hhmm(s.cooldownUntil!)}', style: theme.textTheme.bodySmall),
          if (s.hasKey && s.guardRpd != null)
            Text(
              'Counted by this app: ${s.usedToday} today · ${s.usedLastMinute} in the last minute '
              '(app guard: ${s.guardRpm}/min, ${s.guardRpd}/day)',
              style: theme.textTheme.bodySmall,
            ),
          if (s.state == ProviderState.noVerifiedModel || s.state == ProviderState.blockedPaid)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.detail, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: SelectableText(p.signupUrl, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.accentPrimary))),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: 'https://${p.signupUrl}'));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied — paste it in your browser.')),
                  );
                },
                child: const Text('Copy link'),
              ),
            ],
          ),
          TextField(
            controller: _keyCtl[p.id],
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: s.hasKey ? 'Replace key' : 'Paste API key'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Save & Test',
                  icon: Icons.bolt,
                  loading: _busy[p.id] ?? false,
                  onPressed: () => _saveAndTest(p),
                ),
              ),
              if (s.hasKey) ...[
                const SizedBox(width: AppSpacing.sm),
                Switch(
                  value: s.enabled,
                  onChanged: (v) async {
                    await ApiKeyStore.setEnabled(p.id, v);
                    await _refresh();
                  },
                ),
                IconButton(
                  tooltip: 'Remove key',
                  onPressed: () async {
                    await ApiKeyStore.clear(p.id);
                    AnthropicClient.clearRejected(p.id);
                    await _refresh();
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          if (_result[p.id] != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (_result[p.id]!.isEmpty ? AppColors.success : AppColors.error).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(_result[p.id]!.isEmpty ? 'Test request answered — connection works.' : _result[p.id]!),
            ),
          ],
          if (p.isFree && p.id != 'openrouter')
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Advanced: add a model I verified as free'),
              children: [
                Text(
                  'Only add a model after confirming on ${p.signupUrl.split('/').first} that it is on the FREE tier. '
                  'Unknown models are rejected by default.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _modelCtl[p.id],
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Model ID'),
                ),
                const SizedBox(height: 6),
                SecondaryButton(
                  label: 'Add verified-free model',
                  onPressed: () async {
                    final m = _modelCtl[p.id]!.text.trim();
                    if (m.isEmpty) return;
                    await ApiKeyStore.addUserModel(p.id, m);
                    _modelCtl[p.id]!.clear();
                    await _refresh();
                  },
                ),
                ...models.map((e) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.substring(p.id.length + 1)),
                      subtitle: const Text('User-verified free'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          await ApiKeyStore.removeUserModel(e);
                          await _refresh();
                        },
                      ),
                    )),
                Text(
                  'Built-in allowlist: ${ZeroCostPolicy.allowlistFor(p.id).map((m) => m.id).join(', ')}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
