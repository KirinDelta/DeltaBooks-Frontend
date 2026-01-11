class BookComment {
  final int id;
  final String comment;
  final int? rating; // nullable - rating provided by this user (1-5)
  final CommentUser user;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookComment({
    required this.id,
    required this.comment,
    this.rating,
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
      comment: (json['comment'] as String?) ?? '',
      rating: parseRating(json['rating']),
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
  final String email;
  final String? firstName;
  final String? lastName;

  CommentUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
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
      email: (json['email'] as String?) ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }
}
