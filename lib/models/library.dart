class Library {
  final int id;
  final String name;
  final String? description;
  final int userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Library({
    required this.id,
    required this.name,
    this.description,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Library.fromJson(Map<String, dynamic> json) {
    return Library(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
