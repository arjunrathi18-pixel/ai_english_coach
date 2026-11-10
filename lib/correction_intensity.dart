/// How actively the correction engine intervenes (Prompt 5, section 27).
/// This is a finer-grained replacement for the earlier plain-string
/// correctionMode field — kept as a proper enum so the UI and prompt
/// layer can't drift out of sync on valid values.
enum CorrectionIntensity {
  light,
  balanced,
  detailed,
  strict,
}

extension CorrectionIntensityLabel on CorrectionIntensity {
  String get label {
    switch (this) {
      case CorrectionIntensity.light:
        return 'Light';
      case CorrectionIntensity.balanced:
        return 'Balanced';
      case CorrectionIntensity.detailed:
        return 'Detailed';
      case CorrectionIntensity.strict:
        return 'Strict';
    }
  }

  String get key => toString().split('.').last;

  static CorrectionIntensity fromKey(String key) {
    return CorrectionIntensity.values.firstWhere(
      (c) => c.key == key,
      orElse: () => CorrectionIntensity.balanced,
    );
  }
}
