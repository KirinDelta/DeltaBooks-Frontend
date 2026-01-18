class BookComment {
  final int id;
  final String? comment; // nullable - comment text (may be null if only rating or read status)
  final int? rating; // nullable - rating provided by this user (1-5)
  final String? message; // "read no rating" only if rating and comment are missing but is_read is true
  final CommentUser user;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookComment({
    required this.id,
    this.comment,
    this.rating,
    this.message,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookComment.fromJson(Map<String, dynamic> json) {
    int? parseRating(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    return BookComment(
      id: parseId(json['id']) ?? 0,
      comment: json['comment'] as String?,
      rating: parseRating(json['rating']),
      message: json['message'] as String?,
      user: CommentUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }
}

class CommentUser {
  final int id;
  final String name; // required - always provided by backend
  final String? firstName; // optional
  final String? lastName; // optional
  final String? email; // optional
  final String? username; // optional

  CommentUser({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    this.email,
    this.username,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    return CommentUser(
      id: parseId(json['id']) ?? 0,
      name: (json['name'] as String?) ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String?,
    );
  }
}
