import 'dart:convert';

/// ZERO-COST POLICY (pure Dart — no Flutter imports, so it is unit-testable).
///
/// MAXIMUM AUTHORIZED API SPENDING = $0.00
///  - A model may be used only if it is on the built-in free-model
///    allowlist, was added by the user after verifying it on the provider's
///    free tier, or (OpenRouter) is listed with $0 input AND $0 output
///    pricing by OpenRouter's own model list.
///  - Anything else — including any model whose price is unknown — is
///    rejected.
///  - Paid providers (Anthropic) stay blocked while zero-cost-only mode is
///    ON (the default). They can only be used as the very last fallback
///    after the user switches that mode OFF on purpose.
const double kMaxAuthorizedSpendUsd = 0.0;

class FreeModelSpec {
  final String id;
  final int rpm; // app-side guard, deliberately conservative
  final int rpd; // app-side guard, deliberately conservative
  const FreeModelSpec(this.id, this.rpm, this.rpd);
}

enum ModelPricing { builtInFree, userVerifiedFree, openRouterVerifiedFree, paidOptIn, paid, unknown }

class ModelDecision {
  final bool allowed;
  final ModelPricing pricing;
  final String reason;
  const ModelDecision(this.allowed, this.pricing, this.reason);
}

class ZeroCostPolicy {
  static const Set<String> paidProviders = {'anthropic'};

  /// Free-tier models found in provider documentation / free-tier lists.
  /// The numbers are the app's own conservative guard, NOT the provider's
  /// official limits (the provider's 429 response is always respected).
  static const Map<String, List<FreeModelSpec>> builtInFreeModels = {
    'groq': [
      FreeModelSpec('llama-3.3-70b-versatile', 25, 900),
      FreeModelSpec('llama-3.1-8b-instant', 25, 12000),
    ],
    'cerebras': [
      FreeModelSpec('llama-3.3-70b', 25, 12000),
      FreeModelSpec('gpt-oss-120b', 25, 12000),
    ],
    'gemini': [
      FreeModelSpec('gemini-2.5-flash-lite', 8, 200),
      FreeModelSpec('gemini-2.5-flash', 4, 200),
    ],
  };

  static const int userModelRpm = 8;
  static const int userModelRpd = 150;
  static const int openRouterRpm = 15;
  static const int openRouterRpd = 40;

  static const List<String> openRouterPreferred = [
    'meta-llama/llama-3.3-70b-instruct:free',
    'openai/gpt-oss-120b:free',
    'openai/gpt-oss-20b:free',
    'google/gemma-3-27b-it:free',
  ];

  static bool isPaid(String provider) => paidProviders.contains(provider);

  /// Allowlisted models for a provider (built-in + user-verified).
  static List<FreeModelSpec> allowlistFor(String provider, {Set<String> userVerified = const {}}) {
    final out = <FreeModelSpec>[...(builtInFreeModels[provider] ?? const [])];
    final prefix = '$provider:';
    for (final entry in userVerified) {
      if (!entry.startsWith(prefix)) continue;
      final id = entry.substring(prefix.length);
      if (id.isEmpty || out.any((m) => m.id == id)) continue;
      out.add(FreeModelSpec(id, userModelRpm, userModelRpd));
    }
    return out;
  }

  static ModelDecision check({
    required String provider,
    required String modelId,
    required bool zeroCostOnly,
    Set<String> userVerified = const {},
    Set<String>? openRouterFreeIds,
  }) {
    if (isPaid(provider)) {
      return zeroCostOnly
          ? const ModelDecision(false, ModelPricing.paid, 'Paid provider blocked: zero-cost-only mode is ON.')
          : const ModelDecision(true, ModelPricing.paidOptIn, 'Paid provider enabled by the user (zero-cost-only mode is OFF).');
    }
    if (provider == 'openrouter') {
      if (!modelId.endsWith(':free')) {
        return const ModelDecision(false, ModelPricing.unknown, 'OpenRouter model id must end with :free.');
      }
      if (openRouterFreeIds == null) {
        return const ModelDecision(false, ModelPricing.unknown, 'OpenRouter pricing could not be verified.');
      }
      if (!openRouterFreeIds.contains(modelId)) {
        return const ModelDecision(false, ModelPricing.unknown, 'Model is not listed with \$0 input and output pricing.');
      }
      return const ModelDecision(true, ModelPricing.openRouterVerifiedFree, 'Verified \$0 input/output on OpenRouter.');
    }
    if ((builtInFreeModels[provider] ?? const []).any((m) => m.id == modelId)) {
      return const ModelDecision(true, ModelPricing.builtInFree, 'On the built-in free-model allowlist.');
    }
    if (userVerified.contains('$provider:$modelId')) {
      return const ModelDecision(true, ModelPricing.userVerifiedFree, 'Added by the user as verified free.');
    }
    return const ModelDecision(false, ModelPricing.unknown, 'Model is not on the free allowlist (pricing unknown).');
  }

  /// From OpenRouter's /models JSON: ids ending in ":free" whose EVERY
  /// listed price is exactly zero (and that list both prompt+completion).
  static Set<String> parseOpenRouterFreeIds(String body) {
    final out = <String>{};
    try {
      final data = jsonDecode(body);
      final list = data is Map ? data['data'] : null;
      if (list is! List) return out;
      for (final m in list) {
        if (m is! Map) continue;
        final id = m['id'];
        final pricing = m['pricing'];
        if (id is! String || !id.endsWith(':free') || pricing is! Map) continue;
        if (!pricing.containsKey('prompt') || !pricing.containsKey('completion')) continue;
        var allZero = true;
        for (final v in pricing.values) {
          final n = double.tryParse(v.toString());
          if (n == null || n != 0) {
            allZero = false;
            break;
          }
        }
        if (allZero) out.add(id);
      }
    } catch (_) {
      // unparseable -> nothing is verified -> nothing is allowed
    }
    return out;
  }

  /// Preferred models first, then a few other verified-free ones.
  static List<String> orderOpenRouter(Set<String> freeIds) {
    final ordered = <String>[
      ...openRouterPreferred.where(freeIds.contains),
    ];
    final rest = freeIds.where((id) => !ordered.contains(id)).toList()..sort();
    ordered.addAll(rest.take(3));
    return ordered;
  }
}
