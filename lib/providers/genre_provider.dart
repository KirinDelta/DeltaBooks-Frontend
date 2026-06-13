import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/genre.dart';
import '../services/api_service.dart';

class GenreProvider extends ChangeNotifier {
  final http.Client _client;

  GenreProvider({http.Client? client}) : _client = client ?? http.Client();

  List<Genre> _genres = [];
  bool _isLoading = false;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  List<Genre> get genres => List.unmodifiable(_genres);

  List<Genre> get filteredGenres {
    if (_searchQuery.isEmpty) return genres;
    final q = _searchQuery.toLowerCase();
    return _genres
        .where((g) =>
            g.nameEn.toLowerCase().contains(q) ||
            g.nameRo.toLowerCase().contains(q) ||
            g.slug.contains(q))
        .toList();
  }

  Map<String, List<Genre>> get groupedGenres {
    final Map<String, List<Genre>> groups = {};
    for (final g in filteredGenres) {
      final key = g.nameEn.isNotEmpty ? g.nameEn[0].toUpperCase() : '#';
      groups.putIfAbsent(key, () => []).add(g);
    }
    return groups;
  }

  List<Genre> slugsToGenres(List<String> slugs) {
    final bySlug = {for (final g in _genres) g.slug: g};
    return slugs.map((s) => bySlug[s]).whereType<Genre>().toList();
  }

  String displayNames(List<String> slugs, {bool romanian = false}) {
    final matched = slugsToGenres(slugs);
    if (matched.isEmpty) return '';
    return matched.map((g) => romanian ? g.nameRo : g.nameEn).join(', ');
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchGenres(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/v1/genres');
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        _genres = list
            .map((j) => Genre.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      if (kDebugMode) rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _genres = [];
    _isLoading = false;
    _searchQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
