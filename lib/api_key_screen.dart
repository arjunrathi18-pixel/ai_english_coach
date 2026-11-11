import 'package:flutter/material.dart';
import 'api_key_store.dart';
import 'anthropic_client.dart';
import 'design_tokens.dart';
import 'ui_components.dart';

/// Profile > AI Connection. Paste the Anthropic API key once; it is kept
/// only on this device and works immediately (no rebuild needed).
class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _controller = TextEditingController();
  bool _hasSaved = false;
  bool _testing = false;
  bool _hide = true;
  String? _result;
  bool? _ok;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final saved = await ApiKeyStore.hasSavedKey();
    if (mounted) setState(() => _hasSaved = saved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final k = _controller.text.trim();
    if (k.isEmpty) return;
    await ApiKeyStore.save(k);
    _controller.clear();
    await _refresh();
    await _test();
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _result = null;
      _ok = null;
    });
    final reply = await AnthropicClient.sendMessage(
      systemPrompt: 'Reply with exactly: Connected',
      messages: [
        {"role": "user", "content": "Test"},
      ],
      maxTokens: 20,
    );
    final failed = reply.startsWith('(');
    if (!mounted) return;
    setState(() {
      _testing = false;
      _ok = !failed;
      _result = failed ? reply : 'Connected — the AI is working.';
    });
  }

  Future<void> _clear() async {
    await ApiKeyStore.clear();
    await _refresh();
    setState(() {
      _result = null;
      _ok = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = _hasSaved
        ? 'Using the key saved in this app.'
        : (ApiKeyStore.hasBuildKey ? 'Using the key built into this APK.' : 'No key found yet.');
    return Scaffold(
      appBar: AppBar(title: const Text('AI Connection')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'All speaking, grammar, roleplay and interview features are powered by the Anthropic AI. '
            'Without an API key they cannot generate anything.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(source, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            obscureText: _hide,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Anthropic API key',
              hintText: 'sk-ant-...',
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Save & Test', icon: Icons.bolt, loading: _testing, onPressed: _save),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Test current key', onPressed: _test),
          if (_hasSaved) ...[
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: 'Remove saved key', onPressed: _clear),
          ],
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: ((_ok ?? false) ? AppColors.success : AppColors.error).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(_result!),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'The key is stored only on this phone. Get one at console.anthropic.com.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}
