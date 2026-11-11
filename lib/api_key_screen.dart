import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_providers.dart';
import 'api_key_store.dart';
import 'anthropic_client.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// Profile > AI Connection.
/// The app's AI runs on free services. Add a key for one (Groq is the
/// fastest and takes ~2 minutes) or several — the app uses them in order
/// and switches automatically when one is busy. Keys stay on this phone.
class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final Map<String, TextEditingController> _controllers = {
    for (final p in kAiProviders) p.id: TextEditingController(),
  };
  final Map<String, bool> _busy = {};
  final Map<String, String?> _result = {}; // null = not tested, '' = ok, text = error
  List<String> _connected = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    final c = await ApiKeyStore.connected();
    if (mounted) setState(() => _connected = c);
  }

  Future<void> _saveAndTest(AiProvider p) async {
    final key = _controllers[p.id]!.text.trim();
    if (key.isNotEmpty) {
      await ApiKeyStore.save(p.id, key);
      _controllers[p.id]!.clear();
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

  Future<void> _remove(AiProvider p) async {
    await ApiKeyStore.clear(p.id);
    await _refresh();
    setState(() => _result.remove(p.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Connection')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Text(
              'No payment needed. Add a FREE key for one service below — Groq is the fastest '
              '(sign up, tap "Create API Key", paste it here). Add more than one and the app '
              'switches automatically when a free limit is reached.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _connected.isEmpty
                ? 'Not connected yet.'
                : 'Connected: ${_connected.map((id) => kAiProviders.firstWhere((p) => p.id == id).label).join(', ')}',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (AnthropicClient.lastProviderLabel != null)
            Text('Last reply came from ${AnthropicClient.lastProviderLabel}.',
                style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xl),
          ...kAiProviders.map((p) => _providerCard(theme, p)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Keys are stored only on this phone. Free services have daily limits and may use '
            'prompts to improve their models — do not type private information.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _providerCard(ThemeData theme, AiProvider p) {
    final isConnected = _connected.contains(p.id);
    final res = _result[p.id];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: isConnected ? AppColors.success : theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.label,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (p.isFree)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('FREE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              if (isConnected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(p.tagline, style: theme.textTheme.bodySmall),
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
            controller: _controllers[p.id],
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: isConnected ? 'Replace key' : 'Paste API key',
            ),
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
              if (isConnected) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: 'Remove key',
                  onPressed: () => _remove(p),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          if (res != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (res.isEmpty ? AppColors.success : AppColors.error).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(res.isEmpty ? 'Connected — working.' : res),
            ),
          ],
        ],
      ),
    );
  }
}
