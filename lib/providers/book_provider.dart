import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../services/api_service.dart';
import 'library_provider.dart';
import 'dart:convert';

class BookProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<UserBook> _myBooks = [];
  List<UserBook> _partnerBooks = [];
  bool _isLoading = false;

  List<UserBook> get myBooks => _myBooks;
  List<UserBook> get partnerBooks => _partnerBooks;
  bool get isLoading => _isLoading;

  Future<void> fetchMyBooks({int? libraryId}) async {
    // Prevent multiple simultaneous fetches
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      String endpoint = '/api/v1/user_books';
      if (libraryId != null) {
        endpoint += '?library_id=$libraryId';
      }
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _myBooks = data.map((json) => UserBook.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching my books: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPartnerBooks({int? libraryId}) async {
    // Prevent multiple simultaneous fetches
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      String endpoint = '/api/v1/user_books?partner=true';
      if (libraryId != null) {
        endpoint += '&library_id=$libraryId';
      }
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _partnerBooks = data.map((json) => UserBook.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching partner books: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Book?> findBookByIsbn(String isbn) async {
    try {
      final response = await _apiService.post('/api/v1/books/find', {'isbn': isbn});
      if (response.statusCode == 200) {
        return Book.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error finding book: $e');
    }
    return null;
  }

  /// Search for books using ISBN, title, or author
  /// At least one parameter must be provided
  Future<Book?> searchBooks({
    String? isbn,
    String? title,
    String? author,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (isbn != null && isbn.isNotEmpty) body['isbn'] = isbn;
      if (title != null && title.isNotEmpty) body['title'] = title;
      if (author != null && author.isNotEmpty) body['author'] = author;

      if (body.isEmpty) {
        debugPrint('Error: At least one search parameter is required');
        return null;
      }

      final response = await _apiService.post('/api/v1/books/search', body);
      
      if (response.statusCode == 200) {
        return Book.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null; // Book not found
      } else {
        debugPrint('Error searching books: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error searching books: $e');
      return null;
    }
  }

  /// Add book to library using the new API format
  /// Supports creating new books or adding existing ones
  Future<Map<String, dynamic>?> addBookToLibrary({
    int? bookId,
    String? isbn,
    String? title,
    String? author,
    String? coverUrl,
    int? totalPages,
    String? description,
    double? price,
    int? libraryTotalPages, // Library-specific override
    required int libraryId,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (bookId != null) {
        // Existing book - use book_id
        body['book_id'] = bookId;
        // For existing books, total_pages is only for library-specific override
        if (libraryTotalPages != null && libraryTotalPages > 0) {
          body['total_pages'] = libraryTotalPages;
        }
      } else {
        // New book - provide book data
        if (isbn != null && isbn.isNotEmpty) body['isbn'] = isbn;
        if (title != null && title.isNotEmpty) body['title'] = title;
        if (author != null && author.isNotEmpty) body['author'] = author;
        if (coverUrl != null && coverUrl.isNotEmpty) body['cover_url'] = coverUrl;
        // For new books, use totalPages for book creation
        // If libraryTotalPages is also provided, it will override for the library
        // Note: JSON can't have duplicate keys, so we prioritize library override if provided
        if (libraryTotalPages != null && libraryTotalPages > 0) {
          body['total_pages'] = libraryTotalPages;
        } else if (totalPages != null && totalPages > 0) {
          body['total_pages'] = totalPages;
        }
        if (description != null && description.isNotEmpty) body['description'] = description;
      }
      
      // Library-specific fields
      if (price != null) body['price'] = price;

      final response = await _apiService.post('/api/v1/libraries/$libraryId/share_book', body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData as Map<String, dynamic>;
      } else {
        debugPrint('Error adding book to library: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error adding book to library: $e');
      return null;
    }
  }

  /// Legacy method for backward compatibility
  Future<bool> addBookToLibraryLegacy(int bookId, {int? libraryId}) async {
    if (libraryId == null) return false;
    final result = await addBookToLibrary(
      bookId: bookId,
      libraryId: libraryId,
    );
    return result != null;
  }

  /// Mark a book as read with rating, comment, and read date
  Future<bool> markBookAsRead({
    required int bookId,
    required int libraryId,
    int? rating,
    String? comment,
    DateTime? readAt,
    int? pagesRead,
  }) async {
    try {
      // First, try to find existing user_book for this book
      UserBook? existingUserBook;
      try {
        await fetchMyBooks(libraryId: libraryId);
        existingUserBook = _myBooks.firstWhere(
          (ub) => ub.book.id == bookId,
          orElse: () => throw StateError('Not found'),
        );
      } catch (e) {
        // User book doesn't exist yet, will create new one
        existingUserBook = null;
      }

      // Build user_book object according to API spec
      final userBookData = <String, dynamic>{
        'status': 'finished',
      };
      
      if (rating != null && rating > 0) {
        userBookData['rating'] = rating;
      }
      
      if (comment != null && comment.trim().isNotEmpty) {
        userBookData['review'] = comment.trim();
      } else if (comment != null && comment.trim().isEmpty) {
        // Allow clearing comment by sending empty string
        userBookData['review'] = '';
      }
      
      if (readAt != null) {
        userBookData['read_at'] = readAt.toIso8601String();
      }
      
      if (pagesRead != null && pagesRead > 0) {
        userBookData['pages_read'] = pagesRead;
      }

      // Build request body with nested user_book structure
      final requestBody = <String, dynamic>{
        'user_book': userBookData,
      };
      
      // For POST requests, include book_id and library_id
      if (existingUserBook == null) {
        userBookData['book_id'] = bookId;
        requestBody['library_id'] = libraryId;
      }

      final response = existingUserBook != null
          ? await _apiService.put('/api/v1/user_books/${existingUserBook.id}', requestBody)
          : await _apiService.post('/api/v1/user_books', requestBody);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh libraries to get updated book data
        return true;
      } else {
        debugPrint('Error marking book as read: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error marking book as read: $e');
      return false;
    }
  }

  /// Mark a book as unread by deleting the user_book record
  Future<bool> markBookAsUnread({
    required int bookId,
    required int libraryId,
  }) async {
    try {
      // First, find existing user_book for this book
      UserBook? existingUserBook;
      try {
        await fetchMyBooks(libraryId: libraryId);
        existingUserBook = _myBooks.firstWhere(
          (ub) => ub.book.id == bookId,
          orElse: () => throw StateError('Not found'),
        );
      } catch (e) {
        // User book doesn't exist, nothing to delete
        debugPrint('No user_book found to delete for book $bookId');
        return true; // Already unread
      }

      // Delete the user_book record
      final response = await _apiService.delete('/api/v1/user_books/${existingUserBook.id}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh libraries to get updated book data
        return true;
      } else {
        debugPrint('Error marking book as unread: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error marking book as unread: $e');
      return false;
    }
  }
}
