import 'package:flutter/foundation.dart';
import '../models/library.dart';
import '../services/api_service.dart';
import 'dart:convert';

class LibraryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Library> _libraries = [];
  List<Library> _sharedLibraries = [];
  Library? _selectedLibrary;
  Library? _selectedSharedLibrary;
  bool _isLoading = false;

  List<Library> get libraries => _libraries;
  List<Library> get sharedLibraries => _sharedLibraries;
  // Combined list of all libraries (own + shared), deduplicated by ID
  List<Library> get allLibraries {
    final Map<int, Library> uniqueLibraries = {};
    // Add own libraries first (they take priority)
    for (var library in _libraries) {
      uniqueLibraries[library.id] = library;
    }
    // Add shared libraries only if they're not already in the list
    for (var library in _sharedLibraries) {
      if (!uniqueLibraries.containsKey(library.id)) {
        uniqueLibraries[library.id] = library;
      }
    }
    return uniqueLibraries.values.toList();
  }
  // Check if a library is shared (using the shared field from backend)
  bool isSharedLibrary(Library library) {
    // Safely check the shared field
    try {
      final shared = library.shared;
      return shared == true;
    } catch (e) {
      // Fallback: check if library is in shared libraries list but not in own libraries
      return _sharedLibraries.any((lib) => lib.id == library.id) && 
             !_libraries.any((lib) => lib.id == library.id);
    }
  }
  Library? get selectedLibrary => _selectedLibrary ?? _selectedSharedLibrary;
  Library? get selectedSharedLibrary => _selectedSharedLibrary;
  bool get isLoading => _isLoading;

  Future<void> fetchLibraries() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch own libraries
      final response = await _apiService.get('/api/v1/libraries');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _libraries = data.map((json) {
          try {
            return Library.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Error parsing library: $e');
            debugPrint('Library JSON: $json');
            rethrow;
          }
        }).toList();
        
        // Note: Selection logic will be handled after filtering shared libraries
      } else {
        debugPrint('Error fetching libraries: Status ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      // Filter shared libraries from the main libraries response
      // The backend returns all libraries with a 'shared' field, so we filter client-side
      final allLibraries = List<Library>.from(_libraries);
      _sharedLibraries = allLibraries.where((lib) => lib.shared == true).toList();
      
      // Also remove shared libraries from own libraries list
      _libraries = allLibraries.where((lib) => lib.shared != true).toList();
        
      // Handle library selection after filtering
      final allLibs = [..._libraries, ..._sharedLibraries];
      if (allLibs.isNotEmpty) {
        final currentSelectedId = _selectedLibrary?.id ?? _selectedSharedLibrary?.id;
        if (currentSelectedId == null) {
          // Select first own library, or first shared library if no own libraries
          _selectedLibrary = _libraries.isNotEmpty ? _libraries.first : null;
          _selectedSharedLibrary = _libraries.isEmpty && _sharedLibraries.isNotEmpty 
              ? _sharedLibraries.first 
              : null;
        } else {
          // Find the selected library in the new lists by ID
          Library? ownMatch;
          Library? sharedMatch;
          
          try {
            ownMatch = _libraries.firstWhere((lib) => lib.id == currentSelectedId);
          } catch (e) {
            // Not found in own libraries
          }
          
          try {
            sharedMatch = _sharedLibraries.firstWhere((lib) => lib.id == currentSelectedId);
          } catch (e) {
            // Not found in shared libraries
          }
          
          if (ownMatch != null) {
            _selectedLibrary = ownMatch;
            _selectedSharedLibrary = null;
          } else if (sharedMatch != null) {
            _selectedSharedLibrary = sharedMatch;
            _selectedLibrary = null;
          } else {
            // Selected library no longer exists, select first available
            _selectedLibrary = _libraries.isNotEmpty ? _libraries.first : null;
            _selectedSharedLibrary = _libraries.isEmpty && _sharedLibraries.isNotEmpty 
                ? _sharedLibraries.first 
                : null;
          }
        }
      } else {
        _selectedLibrary = null;
        _selectedSharedLibrary = null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching libraries: $e');
      debugPrint('Stack trace: $stackTrace');
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
    // Check if it's a shared library or own library
    if (isSharedLibrary(library)) {
      _selectedSharedLibrary = library;
      _selectedLibrary = null;
    } else {
      _selectedLibrary = library;
      _selectedSharedLibrary = null;
    }
    notifyListeners();
    // Note: Book fetching should be handled by the UI layer when library changes
  }

  void selectSharedLibrary(Library library) {
    selectLibrary(library); // Use the unified method
  }

  void clearSelection() {
    _selectedLibrary = null;
    notifyListeners();
  }

  void clearSharedSelection() {
    _selectedSharedLibrary = null;
    notifyListeners();
  }
}
