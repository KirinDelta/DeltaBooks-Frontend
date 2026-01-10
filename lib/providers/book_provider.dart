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

  Future<bool> addBookToLibrary(int bookId, {int? libraryId}) async {
    try {
      final body = <String, dynamic>{
        'book_id': bookId,
        'status': 'unread',
      };
      final response = await _apiService.post('/api/v1/user_books', {
        'user_book': body,
        if (libraryId != null) 'library_ids': [libraryId], // Backend expects library_ids as array
      });
      if (response.statusCode == 201) {
        // Books are now included in library response, so we don't need to fetch separately
        return true;
      }
    } catch (e) {
      debugPrint('Error adding book: $e');
    }
    return false;
  }
}
