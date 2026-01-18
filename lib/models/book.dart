import 'book_comment.dart';

class BookPermissions {
  final bool canRemove;

  const BookPermissions({
    this.canRemove = false,
  });

  factory BookPermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const BookPermissions();
    }

    return BookPermissions(
      canRemove: (json['can_remove'] as bool?) ?? false,
    );
  }
}

class Book {
  final int? id;
  /// ID of the library this book is associated with in a library context.
  ///
  /// Expected from backend as `library_id`. This may be null for
  /// global/search results that are not tied to a specific library.
  final int? libraryId;
  /// ID of the library_book association for this book in a library context.
  ///
  /// Expected from backend as `library_book_id`. This may be null for
  /// global/search results that are not tied to a specific library.
  final int? libraryBookId;
  final String isbn;
  final String title;
  final String author;
  final String? coverUrl;
  final int totalPages;
  final String? description;
  final String? source; // 'internal', 'google_books', 'open_library'
  final String? genre;
  final String? seriesName;
  final String? seriesVolume;
  final String? notes; // Library-specific notes
  final double? price; // Library-specific price
  
  // Reading status fields - TOP-LEVEL fields from API
  final bool isReadByMe; // is_read_by_me
  final int? myRating; // my_rating (nullable)
  final String? myComment; // my_comment (nullable)
  final double? averageRating; // average_rating (nullable)
  final int totalCommentsCount; // total_comments_count
  final bool isReadByOthers; // is_read_by_others
  final List<BookComment> comments; // array of all comments from all users
  final List<CircleInteraction> circleInteractions; // array of users who have read the book
  final bool isOwnedGlobally; // is_owned_globally - indicates if book is owned globally (in any library)

  /// Granular permissions for the current user on this book within a library.
  ///
  /// Backed by the `permissions` object from the backend
  /// (e.g. `permissions.can_remove`).
  final BookPermissions permissions;

  /// Convenience accessor mirroring [permissions.canRemove].
  bool get canRemove => permissions.canRemove;

  Book({
    this.id,
    this.libraryId,
    this.libraryBookId,
    required this.isbn,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.totalPages,
    this.description,
    this.source,
    this.genre,
    this.seriesName,
    this.seriesVolume,
    this.notes,
    this.price,
    this.isReadByMe = false,
    this.myRating,
    this.myComment,
    this.averageRating,
    this.totalCommentsCount = 0,
    this.isReadByOthers = false,
    this.comments = const [],
    this.circleInteractions = const [],
    this.isOwnedGlobally = false,
    this.permissions = const BookPermissions(),
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    int? parsePages(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      return null;
    }
    
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    // Parse TOP-LEVEL fields from API (not nested)
    // These fields are always present and never null according to API spec
    final isReadByMe = json['is_read_by_me'] == true;
    final myRating = parseInt(json['my_rating']);
    final myComment = json['my_comment'] as String?;
    final averageRating = parseDouble(json['average_rating']);
    final totalCommentsCount = parseInt(json['total_comments_count']) ?? 0;
    final isReadByOthers = json['is_read_by_others'] == true;
    final isOwnedGlobally = json['is_owned_globally'] == true;
    
    // Parse comments array
    List<BookComment> comments = [];
    if (json['comments'] != null && json['comments'] is List) {
      comments = (json['comments'] as List)
          .map((commentJson) => BookComment.fromJson(commentJson as Map<String, dynamic>))
          .toList();
    }

    // Parse circle_interactions array
    List<CircleInteraction> circleInteractions = [];
    if (json['circle_interactions'] != null && json['circle_interactions'] is List) {
      circleInteractions = (json['circle_interactions'] as List)
          .map((interactionJson) => CircleInteraction.fromJson(interactionJson as Map<String, dynamic>))
          .toList();
    }

    // Parse permissions object for this book (if present)
    final permissions = BookPermissions.fromJson(
      json['permissions'] as Map<String, dynamic>?,
    );
    
    return Book(
      id: parseId(json['id']),
      libraryId: parseId(json['library_id']),
      libraryBookId: parseId(json['library_book_id']),
      isbn: json['isbn'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      totalPages: parsePages(json['total_pages']) ?? 0,
      description: json['description'] as String?,
      source: json['source'] as String?,
      genre: json['genre'] as String?,
      seriesName: json['series'] as String? ?? json['series_name'] as String?,
      seriesVolume: json['series_volume'] as String?,
      notes: json['notes'] as String?,
      price: parseDouble(json['price']),
      // Top-level reading status fields
      isReadByMe: isReadByMe,
      myRating: myRating,
      myComment: myComment,
      averageRating: averageRating,
      totalCommentsCount: totalCommentsCount,
      isReadByOthers: isReadByOthers,
      comments: comments,
      circleInteractions: circleInteractions,
      isOwnedGlobally: isOwnedGlobally,
      permissions: permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (libraryId != null) 'library_id': libraryId,
      if (libraryBookId != null) 'library_book_id': libraryBookId,
      'isbn': isbn,
      'title': title,
      'author': author,
      if (coverUrl != null) 'cover_url': coverUrl,
      'total_pages': totalPages,
      if (description != null) 'description': description,
      if (source != null) 'source': source,
      if (genre != null) 'genre': genre,
      if (seriesName != null) 'series': seriesName,
      if (seriesVolume != null) 'series_volume': seriesVolume,
    };
  }
}

/// Represents a user who has read the book (from circle_interactions)
class CircleInteraction {
  final int userId;
  final String? firstName;
  final String? lastName;
  final bool isRead;

  CircleInteraction({
    required this.userId,
    this.firstName,
    this.lastName,
    this.isRead = true,
  });

  factory CircleInteraction.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    return CircleInteraction(
      userId: parseId(json['user_id']) ?? 0,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      isRead: json['is_read'] == true,
    );
  }
}
