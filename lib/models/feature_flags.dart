class FeatureFlags {
  final Map<String, bool> flags;

  const FeatureFlags(this.flags);

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    final raw = (json['feature_flags'] as Map<String, dynamic>?) ?? {};
    return FeatureFlags(
      raw.map((k, v) => MapEntry(k, v == true)),
    );
  }

  bool isEnabled(String flag) => flags[flag] ?? false;

  static FeatureFlags get defaults => const FeatureFlags({});
}
