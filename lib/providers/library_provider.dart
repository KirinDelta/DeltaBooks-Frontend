import 'package:flutter/foundation.dart';
import '../models/library.dart';
import '../services/api_service.dart';
import 'dart:convert';

class LibraryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Library> _libraries = [];
  Library? _selectedLibrary;
  bool _isLoading = false;

  List<Library> get libraries => _libraries;
  Library? get selectedLibrary => _selectedLibrary;
  bool get isLoading => _isLoading;

  Future<void> fetchLibraries() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/api/v1/libraries');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _libraries = data.map((json) => Library.fromJson(json)).toList();
        
        // If no library is selected and we have libraries, select the first one
        if (_selectedLibrary == null && _libraries.isNotEmpty) {
          _selectedLibrary = _libraries.first;
        }
      }
    } catch (e) {
      debugPrint('Error fetching libraries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createLibrary(String name, {String? description}) async {
    try {
      final response = await _apiService.post('/api/v1/libraries', {
        'library': {
          'name': name,
          if (description != null) 'description': description,
        }
      });
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchLibraries();
        return true;
      }
    } catch (e) {
      debugPrint('Error creating library: $e');
    }
    return false;
  }

  Future<bool> updateLibrary(int libraryId, String name, {String? description}) async {
    try {
      final response = await _apiService.put('/api/v1/libraries/$libraryId', {
        'library': {
          'name': name,
          if (description != null) 'description': description,
        }
      });
      
      if (response.statusCode == 200) {
        await fetchLibraries();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating library: $e');
    }
    return false;
  }

  Future<bool> deleteLibrary(int libraryId) async {
    try {
      final response = await _apiService.delete('/api/v1/libraries/$libraryId');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // If deleted library was selected, clear selection
        if (_selectedLibrary?.id == libraryId) {
          _selectedLibrary = null;
        }
        await fetchLibraries();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting library: $e');
    }
    return false;
  }

  void selectLibrary(Library library) {
    _selectedLibrary = library;
    notifyListeners();
  }

  void clearSelection() {
    _selectedLibrary = null;
    notifyListeners();
  }
}
