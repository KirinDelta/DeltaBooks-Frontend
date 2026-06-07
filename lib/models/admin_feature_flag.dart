class AdminFeatureFlag {
  final String name;
  final String state; // "on" | "off" | "conditional"
  final bool enabledGlobally;
  final List<String> enabledActors;
  final int? percentageOfActors;
  final int? percentageOfTime;
  final List<String> groups;

  AdminFeatureFlag({
    required this.name,
    required this.state,
    required this.enabledGlobally,
    required this.enabledActors,
    this.percentageOfActors,
    this.percentageOfTime,
    required this.groups,
  });

  bool get isOn => state == 'on';
  bool get isConditional => state == 'conditional';
  bool get isOff => state == 'off';

  factory AdminFeatureFlag.fromJson(Map<String, dynamic> json) {
    return AdminFeatureFlag(
      name: json['name'] as String? ?? '',
      state: json['state'] as String? ?? 'off',
      enabledGlobally: json['enabled_globally'] as bool? ?? false,
      enabledActors: (json['enabled_actors'] as List<dynamic>?)
              ?.map((a) => a as String)
              .toList() ??
          [],
      percentageOfActors: (json['percentage_of_actors'] as num?)?.toInt(),
      percentageOfTime: (json['percentage_of_time'] as num?)?.toInt(),
      groups: (json['groups'] as List<dynamic>?)
              ?.map((g) => g as String)
              .toList() ??
          [],
    );
  }
}
