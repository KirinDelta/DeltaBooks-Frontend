class Book {
  final int id;
  final String isbn;
  final String title;
  final String author;
  final String? coverUrl;
  final int totalPages;
  final String? description;

  Book({
    required this.id,
    required this.isbn,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.totalPages,
    this.description,
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
    
    return Book(
      id: parseId(json['id']) ?? 0,
      isbn: json['isbn'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      totalPages: parsePages(json['total_pages']) ?? 0,
      description: json['description'] as String?,
    );
  }
}
