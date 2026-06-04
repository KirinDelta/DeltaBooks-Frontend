class WishlistBook {
  final int id;
  final String isbn;
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final String? genre;
  final int? totalPages;
  final String? seriesName;

  const WishlistBook({
    required this.id,
    required this.isbn,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    this.genre,
    this.totalPages,
    this.seriesName,
  });

  factory WishlistBook.fromJson(Map<String, dynamic> json) {
    return WishlistBook(
      id: (json['id'] as num?)?.toInt() ?? 0,
      isbn: json['isbn'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      description: json['description'] as String?,
      genre: json['genre'] as String?,
      totalPages: (json['total_pages'] as num?)?.toInt(),
      seriesName: json['series_name'] as String? ?? json['series'] as String?,
    );
  }
}

class WishlistItem {
  final int id;
  final String? note;
  final String priority; // 'low', 'medium', 'high'
  final DateTime createdAt;
  final WishlistBook book;

  const WishlistItem({
    required this.id,
    this.note,
    required this.priority,
    required this.createdAt,
    required this.book,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      book: WishlistBook.fromJson(
        (json['book'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  int get priorityOrder {
    switch (priority) {
      case 'high':
        return 2;
      case 'low':
        return 0;
      default:
        return 1;
    }
  }
}
