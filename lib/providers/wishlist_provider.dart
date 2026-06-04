import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/wishlist_item.dart';
import '../services/api_service.dart';

class WishlistProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<WishlistItem> _items = [];
  List<WishlistItem> _partnerItems = [];
  bool _isLoading = false;
  bool _isPartnerLoading = false;

  List<WishlistItem> get items => _items;
  List<WishlistItem> get partnerItems => _partnerItems;
  bool get isLoading => _isLoading;
  bool get isPartnerLoading => _isPartnerLoading;

  bool isWishlisted(int bookId) =>
      _items.any((item) => item.book.id == bookId);

  Future<void> fetchWishlist() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/api/v1/wishlists');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _items = data.map((j) => WishlistItem.fromJson(j)).toList();
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToWishlist(int bookId, {String? note, String priority = 'medium'}) async {
    try {
      final response = await _apiService.post('/api/v1/wishlists', {
        'book_id': bookId,
        if (note != null && note.isNotEmpty) 'note': note,
        'priority': priority,
      });
      if (response.statusCode == 201) {
        final item = WishlistItem.fromJson(jsonDecode(response.body));
        _items.insert(0, item);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateItem(int wishlistId, {String? note, String? priority}) async {
    try {
      final body = <String, dynamic>{};
      if (note != null) body['note'] = note;
      if (priority != null) body['priority'] = priority;

      final response = await _apiService.patch('/api/v1/wishlists/$wishlistId', body);
      if (response.statusCode == 200) {
        final updated = WishlistItem.fromJson(jsonDecode(response.body));
        final idx = _items.indexWhere((i) => i.id == wishlistId);
        if (idx != -1) {
          _items[idx] = updated;
          notifyListeners();
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> removeFromWishlist(int wishlistId) async {
    try {
      final response = await _apiService.delete('/api/v1/wishlists/$wishlistId');
      if (response.statusCode == 204) {
        _items.removeWhere((i) => i.id == wishlistId);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> moveToLibrary(int wishlistId, int libraryId, {String status = 'unread', double? pricePaid}) async {
    try {
      final body = <String, dynamic>{
        'library_id': libraryId,
        'status': status,
        if (pricePaid != null) 'price_paid': pricePaid,
      };
      final response = await _apiService.post('/api/v1/wishlists/$wishlistId/move', body);
      if (response.statusCode == 200) {
        _items.removeWhere((i) => i.id == wishlistId);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> fetchPartnerWishlist(int partnerId) async {
    _isPartnerLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/api/v1/users/$partnerId/wishlist');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _partnerItems = data.map((j) => WishlistItem.fromJson(j)).toList();
      }
    } catch (_) {
    } finally {
      _isPartnerLoading = false;
      notifyListeners();
    }
  }

  void clearPartnerWishlist() {
    _partnerItems = [];
    notifyListeners();
  }
}
