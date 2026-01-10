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
    return Book(
      id: json['id'],
      isbn: json['isbn'],
      title: json['title'],
      author: json['author'],
      coverUrl: json['cover_url'],
      totalPages: json['total_pages'],
      description: json['description'],
    );
  }
}
