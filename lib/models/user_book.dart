import 'book.dart';

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
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    return UserBook(
      id: parseId(json['id']) ?? 0,
      book: Book.fromJson(json['book'] as Map<String, dynamic>),
      status: _statusFromString(json['status'] as String? ?? 'unread'),
      rating: parseInt(json['rating']),
      review: json['review'] as String?,
      pricePaid: json['price_paid'] != null ? (json['price_paid'] as num).toDouble() : null,
      currentPage: parseInt(json['current_page']),
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
