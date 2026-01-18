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
    }
    return null;
  }

  /// Search for books using ISBN, title, or author
  /// At least one parameter must be provided
  /// Returns a list of books (can be empty if no results found)
  Future<List<Book>> searchBooks({
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
        return [];
      }

      final response = await _apiService.post('/api/v1/books/search', body);
      
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // Handle both array and single object responses
        if (responseBody is List) {
          return responseBody.map((json) => Book.fromJson(json as Map<String, dynamic>)).toList();
        } else if (responseBody is Map<String, dynamic>) {
          // Single book returned
          return [Book.fromJson(responseBody)];
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        return []; // No books found
      } else {
        return [];
      }
    } catch (e) {
      return [];
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
    String? genre,
    String? seriesName,
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
        if (genre != null && genre.isNotEmpty) body['genre'] = genre;
        if (seriesName != null && seriesName.isNotEmpty) body['series_name'] = seriesName;
      }
      
      // Library-specific fields
      if (price != null) body['price'] = price;

      final response = await _apiService.post('/api/v1/libraries/$libraryId/share_book', body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
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
        return false;
      }
    } catch (e) {
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
        return true; // Already unread
      }

      // Delete the user_book record
      final response = await _apiService.delete('/api/v1/user_books/${existingUserBook.id}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh libraries to get updated book data
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Update a book in a library using PATCH request
  /// Only library-specific fields can be updated (price, total_pages, series_name, series_volume, notes)
  /// All fields must be wrapped in library_book hash
  Future<Map<String, dynamic>?> updateBookInLibrary({
    required int libraryBookId,
    required int libraryId,
    double? price,
    int? totalPages, // Library-specific page count override
    String? seriesName, // Library-specific series name override
    String? seriesVolume, // Library-specific series volume
    String? notes, // Library-specific notes
  }) async {
    try {
      // Build library_book object - all fields must be inside library_book hash
      final libraryBookData = <String, dynamic>{};
      
      // Library-specific fields only (according to API spec)
      if (price != null) {
        libraryBookData['price'] = price;
      }
      
      if (totalPages != null && totalPages > 0) {
        libraryBookData['total_pages'] = totalPages;
      }
      
      if (seriesName != null) {
        libraryBookData['series_name'] = seriesName.trim().isEmpty ? '' : seriesName.trim();
      }
      
      if (seriesVolume != null) {
        libraryBookData['series_volume'] = seriesVolume.trim().isEmpty ? '' : seriesVolume.trim();
      }
      
      if (notes != null) {
        libraryBookData['notes'] = notes.trim().isEmpty ? '' : notes.trim();
      }

      // Wrap in library_book hash as required by API
      final body = <String, dynamic>{
        'library_book': libraryBookData,
      };

      final response = await _apiService.patch(
        '/api/v1/libraries/$libraryId/library_books/$libraryBookId',
        body,
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseData = jsonDecode(response.body);
        return responseData as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Update a library book using libraryId and bookId
  /// Sends all metadata fields nested inside library_book object
  /// Accepts data with keys: 'isbn', 'title', 'author', 'genre', 'total_pages', 
  /// 'description', 'cover_url', 'series' (maps to series_name), 
  /// 'seriesVolume' (maps to series_volume), 'notes'
  Future<Map<String, dynamic>?> updateLibraryBook({
    required String libraryId,
    required String bookId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Build library_book object with all provided data
      final libraryBookData = <String, dynamic>{};
      
      // Map all fields from data to library_book payload
      if (data.containsKey('isbn')) {
        libraryBookData['isbn'] = data['isbn'];
      }
      
      if (data.containsKey('title')) {
        libraryBookData['title'] = data['title'];
      }
      
      if (data.containsKey('author')) {
        libraryBookData['author'] = data['author'];
      }
      
      if (data.containsKey('genre')) {
        libraryBookData['genre'] = data['genre'];
      }
      
      if (data.containsKey('total_pages')) {
        libraryBookData['total_pages'] = data['total_pages'];
      }
      
      if (data.containsKey('description')) {
        libraryBookData['description'] = data['description'];
      }
      
      if (data.containsKey('cover_url')) {
        libraryBookData['cover_url'] = data['cover_url'];
      }
      
      // Map 'series' from data to 'series_name' in payload (API accepts both, prefer series_name)
      if (data.containsKey('series')) {
        libraryBookData['series_name'] = data['series'];
      }
      
      // Map 'seriesVolume' from data to 'series_volume' in payload
      if (data.containsKey('seriesVolume')) {
        libraryBookData['series_volume'] = data['seriesVolume'];
      }
      
      // Map 'notes' from data to 'notes' in payload
      if (data.containsKey('notes')) {
        libraryBookData['notes'] = data['notes'];
      }
      
      // Map 'price' from data to 'price' in payload
      if (data.containsKey('price')) {
        libraryBookData['price'] = data['price'];
      }

      // Wrap in library_book hash as required by API
      final body = <String, dynamic>{
        'library_book': libraryBookData,
      };

      final response = await _apiService.patch(
        '/api/v1/libraries/$libraryId/library_books/$bookId',
        body,
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseData = jsonDecode(response.body);
        return responseData as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Update local Book object in the provider for immediate UI feedback
  /// This method notifies listeners so BookDetailScreen can reflect changes immediately
  void updateLocalBook(int bookId, Map<String, dynamic> updatedData) {
    // This is a placeholder - actual book updates happen in LibraryProvider
    // We notify listeners so any components listening to BookProvider can react
    notifyListeners();
  }
}
