import 'dart:convert';

/// App-side quota guard (pure Dart). It counts the requests THIS app sends
/// and refuses to send more than a conservative free-tier budget, and it
/// honours cool-downs after a 429. Provider-side quotas are still the real
/// limit; this only keeps the app well inside them. Numbers shown in the UI
/// are what this app counted — never presented as the provider's own data.
abstract class QuotaStorage {
  Future<String?> read();
  Future<void> write(String data);
}

class MemoryQuotaStorage implements QuotaStorage {
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String d) async => data = d;
}

class QuotaCheck {
  final bool allowed;
  final String reason;
  final DateTime? retryAt;
  const QuotaCheck(this.allowed, this.reason, [this.retryAt]);
}

class QuotaGuard {
  QuotaGuard(this._storage, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final QuotaStorage _storage;
  final DateTime Function() _now;

  final Map<String, List<int>> _recent = {}; // key -> epoch ms (last 60 s)
  final Map<String, int> _today = {}; // key -> requests this UTC day
  final Map<String, int> _cooldown = {}; // key -> epoch ms until
  String _dayKey = '';

  String _utcDay(DateTime t) {
    final u = t.toUtc();
    return '${u.year.toString().padLeft(4, '0')}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
  }

  void _rollover() {
    final d = _utcDay(_now());
    if (d != _dayKey) {
      _dayKey = d;
      _today.clear();
    }
  }

  void _trim(String key) {
    final cutoff = _now().millisecondsSinceEpoch - 60000;
    _recent[key]?.removeWhere((t) => t < cutoff);
  }

  Future<void> load() async {
    try {
      final raw = await _storage.read();
      if (raw == null) {
        _rollover();
        return;
      }
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _dayKey = (j['day'] as String?) ?? '';
      (j['today'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _today[k] = (v as num).toInt());
      (j['cooldown'] as Map<String, dynamic>? ?? {}).forEach((k, v) => _cooldown[k] = (v as num).toInt());
    } catch (_) {
      // corrupt data -> start clean (safe: the provider still enforces limits)
    }
    _rollover();
  }

  Future<void> save() async {
    _rollover();
    await _storage.write(jsonEncode({'day': _dayKey, 'today': _today, 'cooldown': _cooldown}));
  }

  QuotaCheck check(String key, int rpm, int rpd) {
    _rollover();
    final nowMs = _now().millisecondsSinceEpoch;
    final until = _cooldown[key];
    if (until != null && until > nowMs) {
      return QuotaCheck(false, 'cooling down after a rate-limit response', DateTime.fromMillisecondsSinceEpoch(until));
    }
    if ((_today[key] ?? 0) >= rpd) {
      return const QuotaCheck(false, 'daily free budget used up (app guard)');
    }
    _trim(key);
    if ((_recent[key]?.length ?? 0) >= rpm) {
      return QuotaCheck(false, 'per-minute budget reached (app guard)', _now().add(const Duration(seconds: 30)));
    }
    return const QuotaCheck(true, 'ok');
  }

  void record(String key) {
    _rollover();
    _recent.putIfAbsent(key, () => []).add(_now().millisecondsSinceEpoch);
    _today[key] = (_today[key] ?? 0) + 1;
  }

  void markRateLimited(String key, {Duration? retryAfter}) {
    final wait = retryAfter ?? const Duration(seconds: 60);
    _cooldown[key] = _now().add(wait).millisecondsSinceEpoch;
  }

  DateTime? cooldownUntil(String key) {
    final until = _cooldown[key];
    if (until == null || until <= _now().millisecondsSinceEpoch) return null;
    return DateTime.fromMillisecondsSinceEpoch(until);
  }

  int usedToday(String key) {
    _rollover();
    return _today[key] ?? 0;
  }

  int usedLastMinute(String key) {
    _trim(key);
    return _recent[key]?.length ?? 0;
  }

  int usedTodayPrefix(String prefix) {
    _rollover();
    var n = 0;
    _today.forEach((k, v) {
      if (k.startsWith(prefix)) n += v;
    });
    return n;
  }

  int usedLastMinutePrefix(String prefix) {
    var n = 0;
    for (final k in _recent.keys.toList()) {
      if (k.startsWith(prefix)) {
        _trim(k);
        n += _recent[k]!.length;
      }
    }
    return n;
  }

  void clearAll() {
    _recent.clear();
    _today.clear();
    _cooldown.clear();
  }
}
