import 'package:flutter/foundation.dart';
import '../models/library.dart';
import '../models/library_member.dart';
import '../models/book.dart';
import '../models/library_stats.dart';
import '../models/book_stats.dart';
import '../services/api_service.dart';
import 'dart:convert';

class LibraryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Library> _libraries = [];
  Library? _selectedLibrary;
  bool _isLoading = false;
  bool _isAscending = true;

  /// Active members/partners for the currently selected library.
  ///
  /// This list is populated from the `/libraries/:id/members` endpoint, which
  /// returns users who have already accepted an invitation.
  List<LibraryMember> _activeMembers = [];
  bool _isMembersLoading = false;

  /// Statistics for a specific library.
  LibraryStats? _libraryStats;
  bool _isStatsLoading = false;

  /// Personal statistics for the current user.
  BookStats? _personalStats;
  bool _isPersonalStatsLoading = false;

  // Combined list of all libraries (own + shared) from API
  List<Library> get libraries => _libraries;
  List<Library> get allLibraries => _libraries;

  /// List of users who currently have access to the selected library.
  List<LibraryMember> get activeMembers => _activeMembers;
  
  // Check if a library is shared (using the shared field from backend)
  bool isSharedLibrary(Library library) {
    return library.shared == true;
  }
  
  Library? get selectedLibrary => _selectedLibrary;
  /// Alias for the currently active library in the UI.
  ///
  /// Exposed as `currentLibrary` so widgets can bind to the active context
  /// without needing to know the internal field name.
  Library? get currentLibrary => _selectedLibrary;
  bool get isLoading => _isLoading;
  bool get isAscending => _isAscending;
  bool get isMembersLoading => _isMembersLoading;
  bool get isStatsLoading => _isStatsLoading;
  LibraryStats? get libraryStats => _libraryStats;
  bool get isPersonalStatsLoading => _isPersonalStatsLoading;
  BookStats? get personalStats => _personalStats;

  /// Retrieve a library instance by its ID from the cached list.
  ///
  /// Returns `null` if no matching library is found.
  Library? getLibraryById(int? id) {
    if (id == null) return null;
    try {
      return _libraries.firstWhere((lib) => lib.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Public helper to force a refresh of libraries from the backend.
  ///
  /// Useful after mutating actions (e.g. removing a book) to ensure any
  /// derived permissions or counts are up to date.
  Future<void> refreshLibrary() async {
    await fetchLibraries();
  }

  /// Update a book in the selected library for immediate UI feedback
  /// Creates a new Library instance with the updated book
  void updateBookInSelectedLibrary(int bookId, Book updatedBook) {
    if (_selectedLibrary == null) return;
    
    // Create a new list of books with the updated book
    final updatedBooks = _selectedLibrary!.books.map((book) {
      if (book.id == bookId) {
        return updatedBook;
      }
      return book;
    }).toList();
    
    // Create a new Library instance with updated books
    final updatedLibrary = Library(
      id: _selectedLibrary!.id,
      name: _selectedLibrary!.name,
      description: _selectedLibrary!.description,
      userId: _selectedLibrary!.userId,
      ownerId: _selectedLibrary!.ownerId,
      createdAt: _selectedLibrary!.createdAt,
      updatedAt: _selectedLibrary!.updatedAt,
      shared: _selectedLibrary!.shared,
      books: updatedBooks,
      isOwner: _selectedLibrary!.isOwner,
      canAddBooksTopLevel: _selectedLibrary!.canAddBooksTopLevel,
      canRemoveBooksTopLevel: _selectedLibrary!.canRemoveBooksTopLevel,
      permissions: _selectedLibrary!.permissions,
    );
    
    // Update the selected library
    _selectedLibrary = updatedLibrary;
    
    // Also update in the libraries list
    _libraries = _libraries.map((lib) {
      if (lib.id == updatedLibrary.id) {
        return updatedLibrary;
      }
      return lib;
    }).toList();
    
    notifyListeners();
  }

  /// Fetch the latest details for a single library, including permissions for
  /// the current user, and merge them into the cached list and selection.
  Future<void> fetchLibraryDetails(int? libraryId) async {
    if (libraryId == null) return;
    try {
      final response =
          await _apiService.get('/api/v1/libraries/$libraryId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updated = Library.fromJson(data as Map<String, dynamic>);

        // Merge into libraries list.
        bool found = false;
        _libraries = _libraries.map((lib) {
          if (lib.id == updated.id) {
            found = true;
            return updated;
          }
          return lib;
        }).toList();
        if (!found) {
          _libraries = [..._libraries, updated];
        }

        // Update currently selected/active library if it matches.
        if (_selectedLibrary?.id == updated.id) {
          _selectedLibrary = updated;
        }
        notifyListeners();
      } else {
        if (kDebugMode) {
          print(
              'Failed to fetch library details: Status ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching library details: $e');
      }
    }
  }

  /// Whether the current user can edit metadata/books in the selected library.
  ///
  /// A user can edit if they own the library or have explicit add-book
  /// permissions from the backend.
  bool get userCanEdit {
    final currentLibrary = _selectedLibrary;
    if (currentLibrary == null) return false;
    return currentLibrary.isOwner || currentLibrary.canAddBooks;
  }

  /// Whether the current user can add books to the selected library.
  bool get userCanAddBooks {
    final currentLibrary = _selectedLibrary;
    if (currentLibrary == null) return false;
    return userCanAddBooksFor(currentLibrary);
  }

  /// Whether the current user can remove books from the selected library.
  bool get userCanRemoveBooks {
    final currentLibrary = _selectedLibrary;
    if (currentLibrary == null) return false;
    return userCanRemoveBooksFor(currentLibrary);
  }

  /// Helper to determine add-book permission for a specific library instance.
  bool userCanAddBooksFor(Library library) {
    return library.isOwner || library.canAddBooks;
  }

  /// Helper to determine remove-book permission for a specific library instance.
  bool userCanRemoveBooksFor(Library library) {
    return library.isOwner || library.canRemoveBooks;
  }

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

  /// Fetch all active members/partners for a library.
  ///
  /// This calls `/api/v1/libraries/:id/members` and stores the resulting users
  /// in [_activeMembers]. The UI surfaces them as "Active Partners".
  Future<void> fetchLibraryMembers(int libraryId) async {
    if (_isMembersLoading) return;

    _isMembersLoading = true;
    notifyListeners();

    try {
      // Clear current list to avoid showing stale/duplicate entries while
      // refetching from the backend.
      _activeMembers = [];

      final response =
          await _apiService.get('/api/v1/libraries/$libraryId/members');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = jsonDecode(response.body);
          final fetched = data
              .map((json) =>
                  LibraryMember.fromJson(json as Map<String, dynamic>))
              .toList();

          // Ensure uniqueness by member ID to prevent duplicates if the
          // backend ever returns the same record more than once.
          final seenIds = <int>{};
          _activeMembers = fetched.where((member) {
            if (seenIds.contains(member.id)) return false;
            seenIds.add(member.id);
            return true;
          }).toList();
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing library members response: $e');
            print('Response body: ${response.body}');
          }
          _activeMembers = [];
        }
      } else {
        if (kDebugMode) {
          print(
              'Failed to fetch library members: Status ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        // Keep existing members on error.
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching library members: $e');
      }
      // Keep existing members on network error.
    } finally {
      _isMembersLoading = false;
      notifyListeners();
    }
  }

  /// Update member permissions (can add/remove books) for a specific member.
  ///
  /// Returns `null` on success or a human-readable error message on failure.
  Future<String?> updateMemberPermissions(
    int libraryId,
    int memberId,
    bool canAdd,
    bool canRemove,
  ) async {
    try {
      // Build a clean payload for the API request.
      final payload = {
        'member': {
          'can_add_books': canAdd,
          'can_remove_books': canRemove,
        },
      };

      final response = await _apiService.patch(
        '/api/v1/libraries/$libraryId/members/$memberId',
        payload,
      );

      if (response.statusCode == 200) {
        try {
          // Prefer the backend's canonical version of the member to keep UI in sync.
          final data = jsonDecode(response.body);
          // Handle either `{ member: {...} }` or a bare member object.
          final memberJson = data is Map<String, dynamic> &&
                  data['member'] is Map<String, dynamic>
              ? data['member'] as Map<String, dynamic>
              : (data as Map<String, dynamic>);

          final updatedMember = LibraryMember.fromJson(memberJson);

          _activeMembers = _activeMembers.map((member) {
            if (member.id == memberId) {
              return updatedMember;
            }
            return member;
          }).toList();
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing updated member response: $e');
            print('Response body: ${response.body}');
          }
          // Fallback: if parsing fails, still update locally with the requested values.
          _activeMembers = _activeMembers.map((member) {
            if (member.id == memberId) {
              return member.copyWith(
                canAddBooks: canAdd,
                canRemoveBooks: canRemove,
              );
            }
            return member;
          }).toList();
        }

        notifyListeners();
        return null;
      }

      if (kDebugMode) {
        print(
            'Failed to update member permissions: Status ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data['error']?.toString() ??
              data['message']?.toString() ??
              'Failed to update permissions';
        }
      } catch (_) {
        // Ignore JSON parse errors and fall back to generic error.
      }

      return 'Failed to update permissions';
    } catch (e) {
      if (kDebugMode) {
        print('Error updating member permissions: $e');
      }
      return 'Error: ${e.toString()}';
    }
  }

  /// Fetch library statistics for a specific library.
  ///
  /// Calls `/api/v1/libraries/:id/stats?year=X&scope=Y` and stores the result in [_libraryStats].
  /// [year] is optional - if provided, filters stats for that year.
  /// [scope] is optional - if provided, filters stats by scope ('all' or 'personal'/'just_me').
  Future<void> fetchLibraryStats(String libraryId, {int? year, String? scope}) async {
    if (_isStatsLoading) return;

    _isStatsLoading = true;
    notifyListeners();

    try {
      _libraryStats = null;

      // Build URL with optional year and scope parameters
      String url = '/api/v1/libraries/$libraryId/stats';
      final queryParams = <String>[];
      if (year != null) {
        queryParams.add('year=$year');
      }
      if (scope != null) {
        queryParams.add('scope=$scope');
      }
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await _apiService.get(url);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          _libraryStats = LibraryStats.fromJson(data);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing library stats response: $e');
            print('Response body: ${response.body}');
          }
          _libraryStats = null;
        }
      } else {
        if (kDebugMode) {
          print(
              'Failed to fetch library stats: Status ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        _libraryStats = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching library stats: $e');
      }
      _libraryStats = null;
    } finally {
      _isStatsLoading = false;
      notifyListeners();
    }
  }

  /// Fetch personal statistics for the current user.
  ///
  /// Calls `/api/v1/statistics/personal?year=X` and stores the result in [_personalStats].
  /// [year] is optional - if provided, filters stats for that year.
  Future<void> fetchPersonalStats({int? year}) async {
    if (_isPersonalStatsLoading) return;

    _isPersonalStatsLoading = true;
    notifyListeners();

    try {
      _personalStats = null;

      // Build URL with optional year parameter
      String url = '/api/v1/statistics/personal';
      if (year != null) {
        url += '?year=$year';
      }

      final response = await _apiService.get(url);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          _personalStats = BookStats.fromJson(data);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing personal stats response: $e');
            print('Response body: ${response.body}');
          }
          _personalStats = null;
        }
      } else {
        if (kDebugMode) {
          print(
              'Failed to fetch personal stats: Status ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        _personalStats = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching personal stats: $e');
      }
      _personalStats = null;
    } finally {
      _isPersonalStatsLoading = false;
      notifyListeners();
    }
  }

  /// Remove/revoke a member's access to the library.
  ///
  /// Returns `null` on success or a human-readable error message on failure.
  Future<String?> removeMember(int libraryId, int memberId) async {
    try {
      final response = await _apiService
          .delete('/api/v1/libraries/$libraryId/members/$memberId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _activeMembers =
            _activeMembers.where((member) => member.id != memberId).toList();
        notifyListeners();
        return null;
      }

      if (kDebugMode) {
        print(
            'Failed to remove library member: Status ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data['error']?.toString() ??
              data['message']?.toString() ??
              'Failed to remove partner';
        }
      } catch (_) {
        // Ignore JSON parse errors and fall back to generic error.
      }

      return 'Failed to remove partner';
    } catch (e) {
      if (kDebugMode) {
        print('Error removing library member: $e');
      }
      return 'Error: ${e.toString()}';
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

  /// Remove a book from the currently selected library.
  ///
  /// This will:
  /// - Call the backend DELETE API to remove the book from the library
  /// - Optimistically update the local libraries list so the UI reflects
  ///   the removal immediately without requiring a manual refresh.
  ///
  /// Returns `null` on success, or an error message on failure.
  Future<String?> removeBook(int bookId) async {
    final currentLibrary = _selectedLibrary;
    if (currentLibrary == null) {
      return 'No library selected';
    }

    try {
      final response = await _apiService.delete(
        '/api/v1/libraries/${currentLibrary.id}/books/$bookId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove the book from the selected library's local books list
        final updatedBooks = currentLibrary.books
            .where((book) => book.id != bookId)
            .toList();

        final updatedLibrary = Library(
          id: currentLibrary.id,
          name: currentLibrary.name,
          description: currentLibrary.description,
          userId: currentLibrary.userId,
          createdAt: currentLibrary.createdAt,
          updatedAt: currentLibrary.updatedAt,
          shared: currentLibrary.shared,
          books: updatedBooks,
          isOwner: currentLibrary.isOwner,
          permissions: currentLibrary.permissions,
        );

        // Update the internal libraries list
        _libraries = _libraries.map((library) {
          if (library.id == currentLibrary.id) {
            return updatedLibrary;
          }
          return library;
        }).toList();

        // Update the selected library reference
        _selectedLibrary = updatedLibrary;

        notifyListeners();
        return null;
      }

      if (kDebugMode) {
        print(
            'Failed to remove book from library: Status ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      // Attempt to extract a useful error message from the response, if any
      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data['error']?.toString() ??
              data['message']?.toString() ??
              'Failed to remove book from library';
        }
      } catch (_) {
        // Ignore JSON parse errors and fall back to generic error
      }

      return 'Failed to remove book from library';
    } catch (e) {
      if (kDebugMode) {
        print('Error removing book from library: $e');
      }
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
