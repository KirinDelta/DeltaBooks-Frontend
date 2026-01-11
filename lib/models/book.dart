import 'book_comment.dart';

class Book {
  final int? id;
  final String isbn;
  final String title;
  final String author;
  final String? coverUrl;
  final int totalPages;
  final String? description;
  final String? source; // 'internal', 'google_books', 'open_library'
  final String? genre;
  final String? seriesName;
  
  // Reading status fields - TOP-LEVEL fields from API
  final bool isReadByMe; // is_read_by_me
  final int? myRating; // my_rating (nullable)
  final String? myComment; // my_comment (nullable)
  final double? averageRating; // average_rating (nullable)
  final int totalCommentsCount; // total_comments_count
  final bool isReadByOthers; // is_read_by_others
  final List<BookComment> comments; // array of all comments from all users
  final bool isOwnedGlobally; // is_owned_globally - indicates if book is owned globally (in any library)

  Book({
    this.id,
    required this.isbn,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.totalPages,
    this.description,
    this.source,
    this.genre,
    this.seriesName,
    this.isReadByMe = false,
    this.myRating,
    this.myComment,
    this.averageRating,
    this.totalCommentsCount = 0,
    this.isReadByOthers = false,
    this.comments = const [],
    this.isOwnedGlobally = false,
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
    
    return Book(
      id: parseId(json['id']),
      isbn: json['isbn'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      totalPages: parsePages(json['total_pages']) ?? 0,
      description: json['description'] as String?,
      source: json['source'] as String?,
      genre: json['genre'] as String?,
      seriesName: json['series_name'] as String?,
      // Top-level reading status fields
      isReadByMe: isReadByMe,
      myRating: myRating,
      myComment: myComment,
      averageRating: averageRating,
      totalCommentsCount: totalCommentsCount,
      isReadByOthers: isReadByOthers,
      comments: comments,
      isOwnedGlobally: isOwnedGlobally,
    );
  }
}
