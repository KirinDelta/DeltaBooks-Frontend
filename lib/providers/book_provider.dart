import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../services/api_service.dart';
import 'dart:convert';

class BookProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<UserBook> _myBooks = [];
  List<UserBook> _partnerBooks = [];
  bool _isLoading = false;

  List<UserBook> get myBooks => _myBooks;
  List<UserBook> get partnerBooks => _partnerBooks;
  bool get isLoading => _isLoading;

  Future<void> fetchMyBooks() async {
    // Prevent multiple simultaneous fetches
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/api/v1/user_books');
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

  Future<void> fetchPartnerBooks() async {
    // Prevent multiple simultaneous fetches
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/api/v1/user_books?partner=true');
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

  Future<bool> addBookToLibrary(int bookId) async {
    try {
      final response = await _apiService.post('/api/v1/user_books', {
        'user_book': {'book_id': bookId, 'status': 'unread'}
      });
      if (response.statusCode == 201) {
        await fetchMyBooks();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding book: $e');
    }
    return false;
  }
}
