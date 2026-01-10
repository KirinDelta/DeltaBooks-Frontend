class User {
  final int id;
  final String email;

  User({required this.id, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['data']['id'],
      email: json['email'] ?? json['data']['email'],
    );
  }
}
