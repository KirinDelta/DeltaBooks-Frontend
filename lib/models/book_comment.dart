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
    
    return BookComment(
      id: json['id'] as int,
      comment: json['comment'] as String,
      rating: parseRating(json['rating']),
      user: CommentUser.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class CommentUser {
  final int id;
  final String email;

  CommentUser({
    required this.id,
    required this.email,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['id'] as int,
      email: json['email'] as String,
    );
  }
}
