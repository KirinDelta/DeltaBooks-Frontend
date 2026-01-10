enum BookStatus { unread, reading, finished }

class UserBook {
  final int id;
  final Book book;
  final BookStatus status;
  final int? rating;
  final String? review;
  final double? pricePaid;
  final int? currentPage;

  UserBook({
    required this.id,
    required this.book,
    required this.status,
    this.rating,
    this.review,
    this.pricePaid,
    this.currentPage,
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'],
      book: Book.fromJson(json['book']),
      status: _statusFromString(json['status']),
      rating: json['rating'],
      review: json['review'],
      pricePaid: json['price_paid']?.toDouble(),
      currentPage: json['current_page'],
    );
  }

  static BookStatus _statusFromString(String status) {
    switch (status) {
      case 'reading':
        return BookStatus.reading;
      case 'finished':
        return BookStatus.finished;
      default:
        return BookStatus.unread;
    }
  }
}
