class User {
  final int id;
  final String email;

  User({required this.id, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    return User(
      id: parseId(json['id']) ?? parseId(json['data']?['id']) ?? 0,
      email: (json['email'] as String?) ?? (json['data']?['email'] as String?) ?? '',
    );
  }
}
