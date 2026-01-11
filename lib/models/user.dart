class User {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? defaultCurrency;
  final String? defaultLanguage;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.defaultCurrency,
    this.defaultLanguage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    final data = json['data'] ?? json;
    
    return User(
      id: parseId(json['id']) ?? parseId(data['id']) ?? 0,
      email: (json['email'] as String?) ?? (data['email'] as String?) ?? '',
      firstName: json['first_name'] as String? ?? data['first_name'] as String?,
      lastName: json['last_name'] as String? ?? data['last_name'] as String?,
      username: json['username'] as String? ?? data['username'] as String?,
      defaultCurrency: json['default_currency'] as String? ?? data['default_currency'] as String?,
      defaultLanguage: json['default_language'] as String? ?? data['default_language'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'default_currency': defaultCurrency,
      'default_language': defaultLanguage,
    };
  }
}
