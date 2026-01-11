import 'package:flutter/foundation.dart';
import '../models/library.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import 'dart:convert';

class LibraryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Library> _libraries = [];
  Library? _selectedLibrary;
  bool _isLoading = false;
  bool _isAscending = true;

  // Combined list of all libraries (own + shared) from API
  List<Library> get libraries => _libraries;
  List<Library> get allLibraries => _libraries;
  
  // Check if a library is shared (using the shared field from backend)
  bool isSharedLibrary(Library library) {
    return library.shared == true;
  }
  
  Library? get selectedLibrary => _selectedLibrary;
  bool get isLoading => _isLoading;
  bool get isAscending => _isAscending;

  void setSortAscending(bool ascending) {
    if (_isAscending != ascending) {
      _isAscending = ascending;
      notifyListeners();
    }
  }

  void toggleSortDirection() {
    _isAscending = !_isAscending;
    notifyListeners();
  }

  Future<void> fetchLibraries() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch all libraries (owned + shared) - API returns combined list
      final response = await _apiService.get('/api/v1/libraries');
      
      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = jsonDecode(response.body);
          final fetchedLibraries = data.map((json) {
            try {
              return Library.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing library: $e');
                print('Library JSON: $json');
              }
              rethrow;
            }
          }).toList();
          
          _libraries = fetchedLibraries;
          
          // Handle library selection
          if (_libraries.isNotEmpty) {
            final currentSelectedId = _selectedLibrary?.id;
            if (currentSelectedId == null) {
              // Select first library
              _selectedLibrary = _libraries.first;
            } else {
              // Try to find the selected library in the new list
              try {
                _selectedLibrary = _libraries.firstWhere((lib) => lib.id == currentSelectedId);
              } catch (e) {
                // Selected library no longer exists, select first available
                _selectedLibrary = _libraries.first;
              }
            }
          } else {
            _selectedLibrary = null;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing libraries response: $e');
            print('Response body: ${response.body}');
          }
          // Reset libraries on parse error
          _libraries = [];
          _selectedLibrary = null;
        }
      } else {
        if (kDebugMode) {
          print('Failed to fetch libraries: Status ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        // Don't clear libraries on error - keep existing state
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching libraries: $e');
      }
      // Don't clear libraries on network error - keep existing state
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createLibrary(String name, {String? description}) async {
    try {
      final response = await _apiService.post('/api/v1/libraries', {
        'library': {
          'name': name,
          if (description != null) 'description': description,
        }
      });
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchLibraries();
        return null; // Success
      }
      
      // Extract error message from response
      if (response.statusCode == 403) {
        try {
          final data = jsonDecode(response.body);
          return data['error'] ?? data['message'] ?? 'Permission denied';
        } catch (e) {
          return 'Permission denied';
        }
      }
      
      return 'Failed to create library';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  Future<String?> updateLibrary(int libraryId, String name, {String? description}) async {
    try {
      final response = await _apiService.put('/api/v1/libraries/$libraryId', {
        'library': {
          'name': name,
          if (description != null) 'description': description,
        }
      });
      
      if (response.statusCode == 200) {
        await fetchLibraries();
        return null; // Success
      }
      
      // Extract error message from response
      if (response.statusCode == 403) {
        try {
          final data = jsonDecode(response.body);
          return data['error'] ?? data['message'] ?? 'Permission denied';
        } catch (e) {
          return 'Permission denied';
        }
      }
      
      return 'Failed to update library';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  Future<String?> deleteLibrary(int libraryId) async {
    try {
      final response = await _apiService.delete('/api/v1/libraries/$libraryId');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // If deleted library was selected, clear selection
        if (_selectedLibrary?.id == libraryId) {
          _selectedLibrary = null;
        }
        await fetchLibraries();
        return null; // Success
      }
      
      // Extract error message from response
      if (response.statusCode == 403) {
        try {
          final data = jsonDecode(response.body);
          return data['error'] ?? data['message'] ?? 'Permission denied';
        } catch (e) {
          return 'Permission denied';
        }
      }
      
      return 'Failed to delete library';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  void selectLibrary(Library library) {
    _selectedLibrary = library;
    notifyListeners();
    // Note: Book fetching should be handled by the UI layer when library changes
  }

  void clearSelection() {
    _selectedLibrary = null;
    notifyListeners();
  }

  /// Filter books by search query
  /// Checks title, ISBN, series name, and genre
  List<Book> filterBooksBySearch(List<Book> books, String query) {
    if (query.trim().isEmpty) {
      return books;
    }
    
    final lowerQuery = query.toLowerCase().trim();
    
    return books.where((book) {
      // Check title
      if (book.title.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Check ISBN
      if (book.isbn.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Check series name (if exists)
      if (book.seriesName != null && book.seriesName!.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Check genre (if exists)
      if (book.genre != null && book.genre!.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      return false;
    }).toList();
  }
}
