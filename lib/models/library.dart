import 'book.dart';

class Library {
  final int id;
  final String name;
  final String? description;
  final int userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool shared;
  final List<Book> books;

  Library({
    required this.id,
    required this.name,
    this.description,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.shared = false,
    this.books = const [],
  });

  factory Library.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    // Parse books array if present
    List<Book> books = [];
    if (json['books'] != null && json['books'] is List) {
      books = (json['books'] as List)
          .map((bookJson) => Book.fromJson(bookJson as Map<String, dynamic>))
          .toList();
    }
    
    return Library(
      id: parseId(json['id']) ?? 0,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      userId: parseId(json['user_id']) ?? parseId(json['owner']?['id']) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
      shared: (json['shared'] as bool?) ?? false,
      books: books,
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
