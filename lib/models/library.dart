import 'book.dart';

class Library {
  final int id;
  final String name;
  final String? description;
  final int userId;
  /// ID of the library owner (may be the same as [userId]).
  ///
  /// Expected from backend as `owner_id`.
  final int? ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool shared;
  final List<Book> books;

  /// Whether the currently authenticated user owns this library.
  ///
  /// Expected to be provided by the backend as `is_owner`.
  final bool isOwner;

  /// Raw permissions map for the current user on this library.
  ///
  /// Populated from the `user_permissions` object returned by the backend.
  final Map<String, dynamic>? permissions;

  /// Convenience fields derived from [permissions] for easier access.
  bool get canAddBooks => permissions?['can_add_books'] == true;

  /// Supports both `can_remove` and `can_remove_books` keys from backend.
  bool get canRemoveBooks =>
      permissions?['can_remove'] == true ||
      permissions?['can_remove_books'] == true;

  Library({
    required this.id,
    required this.name,
    this.description,
    required this.userId,
    this.ownerId,
    required this.createdAt,
    this.updatedAt,
    this.shared = false,
    this.books = const [],
    this.isOwner = false,
    this.permissions,
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
    
    final shared = (json['shared'] as bool?) ?? false;

    // Best-effort parsing for ownership and permissions; defaults maintain
    // previous behaviour (full control for owners, read-only for shared).
    final isOwner = (json['is_owner'] as bool?) ??
        // Fallback: treat non-shared libraries as owned by current user.
        !shared;

    // Raw per-user permissions map (for invited partners, owners, etc.)
    final Map<String, dynamic>? permissions =
        json['user_permissions'] as Map<String, dynamic>?;
    
    return Library(
      id: parseId(json['id']) ?? 0,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      userId: parseId(json['user_id']) ?? parseId(json['owner']?['id']) ?? 0,
      ownerId: parseId(json['owner_id']) ?? parseId(json['owner']?['id']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
      shared: shared,
      books: books,
      isOwner: isOwner,
      permissions: permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'user_id': userId,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
