import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../providers/auth_provider.dart';
import '../models/book.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import 'book_detail_screen.dart';

enum SortOption {
  recent,
  rating,
  pages,
  title,
}

enum FilterOption {
  unread,
  read,
  inCircle,
}

class LibraryScreen extends StatefulWidget {
  final GlobalKey<LibraryScreenState>? libraryScreenKey;
  
  const LibraryScreen({super.key, this.libraryScreenKey});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  int? _lastLibraryId;
  SortOption _currentSort = SortOption.recent;
  Set<FilterOption> _activeFilters = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFilterBarExpanded = false;
  final ScrollController _scrollController = ScrollController();
  String _previousSearchQuery = '';
  final ValueNotifier<int> _filteredBookCountNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // Initialize the filtered count notifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBooks();
      _updateFilteredCount();
    });
  }

  void _updateFilteredCount() {
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final selectedLibrary = libraryProvider.selectedLibrary;
    final books = selectedLibrary?.books ?? [];
    final filteredAndSortedBooks = _applyFiltersAndSort(books);
    _filteredBookCountNotifier.value = filteredAndSortedBooks.length;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _filteredBookCountNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    // Reset scroll position when search query changes
    if (_previousSearchQuery != value) {
      _previousSearchQuery = value;
      _resetScrollPosition();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _previousSearchQuery = '';
    });
    _resetScrollPosition();
  }

  void _resetScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void showSortBottomSheetFromParent() {
    // Sort options are now in the floating bar, so expand it instead
    setState(() {
      _isFilterBarExpanded = true;
    });
  }

  /// Returns the count of books after applying current filters and search
  int getFilteredBookCount() {
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final selectedLibrary = libraryProvider.selectedLibrary;
    final books = selectedLibrary?.books ?? [];
    final filteredAndSortedBooks = _applyFiltersAndSort(books);
    return filteredAndSortedBooks.length;
  }

  /// Returns the ValueNotifier for filtered book count (for external listeners)
  ValueNotifier<int> get filteredBookCountNotifier => _filteredBookCountNotifier;

  Future<void> _fetchBooks() async {
    // Books are now included in the library object from the API
    // No need to fetch separately - books come with the library
    if (mounted) {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      final selectedLibrary = libraryProvider.selectedLibrary;
      if (selectedLibrary != null) {
        final libraryId = selectedLibrary.id;
        if (libraryId != _lastLibraryId) {
          _lastLibraryId = libraryId;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Listen to library changes to refresh books - this will trigger rebuild when library updates
    final libraryProvider = Provider.of<LibraryProvider>(context);
    
    // Refresh books when library changes
    final selectedLibrary = libraryProvider.selectedLibrary;
    final currentLibraryId = selectedLibrary?.id;
    if (currentLibraryId != _lastLibraryId && currentLibraryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchBooks();
        }
      });
    }
    
    // Show books from selected library - books are included in the library object
    final isShared = selectedLibrary != null && libraryProvider.isSharedLibrary(selectedLibrary);
    final books = selectedLibrary?.books ?? [];

    final bool canRemoveBooks =
        selectedLibrary != null && libraryProvider.userCanRemoveBooksFor(selectedLibrary);
    
    // Update last library ID to track changes
    if (currentLibraryId != null && currentLibraryId != _lastLibraryId) {
      _lastLibraryId = currentLibraryId;
      // Update filtered count when library changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateFilteredCount();
      });
    }

    if (libraryProvider.isLoading && _lastLibraryId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Future<void> _refreshData() async {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      final selectedLibrary = libraryProvider.selectedLibrary;
      
      // Refresh libraries - books are included in the response
      await libraryProvider.fetchLibraries();
      
      // Update last library ID to trigger refresh if needed
      if (selectedLibrary != null) {
        _lastLibraryId = selectedLibrary.id;
      }
    }

    // Apply filtering and sorting
    final filteredAndSortedBooks = _applyFiltersAndSort(books);
    
    // Update the filtered count notifier for the top dropdown (defer to avoid setState during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateFilteredCount();
      }
    });

    // Determine if library is empty (no books at all) vs filters returned no results
    final isLibraryEmpty = books.isEmpty && !libraryProvider.isLoading;
    final hasSearchQuery = _searchQuery.trim().isNotEmpty;
    final hasNoFilterResults = filteredAndSortedBooks.isEmpty && !isLibraryEmpty && !libraryProvider.isLoading;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          // Floating filter bar - always at the top
          _buildFloatingFilterBar(context, l10n, filteredAndSortedBooks),
          // Books list or empty state - takes remaining space
          Expanded(
            child: hasNoFilterResults
                ? Center(
                    child: Text(
                      hasSearchQuery ? l10n.noBooksFoundSearch : l10n.noResults,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  )
                : isLibraryEmpty
                    ? Center(
                        child: Text(
                          isShared ? l10n.emptyPartnerLibrary : l10n.emptyLibrary,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredAndSortedBooks.length,
        itemBuilder: (context, index) {
        final book = filteredAndSortedBooks[index];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.user?.id;
        
        // Determine if current user has read it - use new field
        final hasRead = book.isReadByMe;
        final partnerHasRead = book.isReadByOthers;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.riverMist),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 4),
                blurRadius: 12,
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              if (selectedLibrary != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(
                      book: book,
                      libraryId: selectedLibrary.id,
                    ),
                  ),
                );
                // Refresh library when returning from detail screen
                if (mounted) {
                  final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
                  await libraryProvider.fetchLibraries();
                }
              }
            },
            onLongPress: canRemoveBooks
                ? () => _confirmAndRemoveBookFromLibrary(context, book)
                : null,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Book Cover with Sub-Cover Metadata
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: book.coverUrl != null
                                ? Image.network(
                                    book.coverUrl!,
                                    width: 60,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 90,
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.book,
                                        color: Colors.grey[600],
                                        size: 30,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.book,
                                      color: Colors.grey[600],
                                      size: 30,
                                    ),
                                  ),
                          ),
                          // Sub-Cover Metadata - Pages and Genre
                          if (book.totalPages > 0 || (book.genre != null && book.genre!.isNotEmpty)) ...[
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 60,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Pages row
                                  if (book.totalPages > 0)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.menu_book_rounded,
                                          size: 10,
                                          color: AppColors.deltaTeal.withOpacity(0.4),
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            '${book.totalPages} pgs',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  // Genre (if available)
                                  if (book.genre != null && book.genre!.isNotEmpty) ...[
                                    if (book.totalPages > 0) const SizedBox(height: 2),
                                    Text(
                                      book.genre!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 9,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Middle: Expanded Column with Title, Author, Series, Rating and Comments
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.deltaTeal,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              book.author,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            // Series name (if available)
                            if (book.seriesName != null && book.seriesName!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '📚 ',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 14,
                                        ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Series: ${book.seriesName!}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Star Rating and Comment Count Row
                            Row(
                              children: [
                                // Star rating (Gold Leaf) - use average_rating, show empty stars if 0
                                ...List.generate(5, (index) {
                                  final rating = book.averageRating ?? 0.0;
                                  final starIndex = index + 1;
                                  final isFilled = starIndex <= rating.round();
                                  final isHalf = starIndex - 0.5 <= rating && rating < starIndex;
                                  
                                  return Icon(
                                    isFilled
                                        ? Icons.star
                                        : isHalf
                                            ? Icons.star_half
                                            : Icons.star_border,
                                    color: AppColors.goldLeaf,
                                    size: 14,
                                  );
                                }),
                                if (book.averageRating != null && book.averageRating! > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    book.averageRating!.toStringAsFixed(1),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.deltaTeal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 12),
                                // Comments count with speech bubble icon
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: AppColors.deltaTeal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  book.totalCommentsCount.toString(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.deltaTeal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Vertical Divider
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: AppColors.riverMist,
                      ),
                      // Right: Spacer for READ badge area (positioned absolutely)
                      SizedBox(width: 50),
                    ],
                  ),
                ),
                // Top right: READ badge
                if (hasRead)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goldLeaf,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'READ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Bottom right: Avatars
                // Show if isReadByOthers is true (partner has read it)
                if (book.isReadByOthers)
                  Builder(
                    builder: (context) {
                      final avatars = _buildOtherReadersAvatars(book, currentUserId);
                      if (avatars.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        bottom: 8,
                        right: 8,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: avatars,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
                      ),
          ),
        ],
      ),
    );
  }

  List<Book> _applyFiltersAndSort(List<Book> books) {
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    
    // First apply search filter if there's a query
    List<Book> filtered = books;
    if (_searchQuery.trim().isNotEmpty) {
      filtered = libraryProvider.filterBooksBySearch(filtered, _searchQuery);
    }
    
    // Then apply status filters with AND logic - all selected filters must be satisfied
    if (_activeFilters.isEmpty) {
      // No status filters selected, return search-filtered books
      return _applySorting(filtered);
    }
    
    final hasUnread = _activeFilters.contains(FilterOption.unread);
    final hasRead = _activeFilters.contains(FilterOption.read);
    final hasInCircle = _activeFilters.contains(FilterOption.inCircle);
    
    // If both Read and Unread are selected, return empty list (contradiction)
    if (hasUnread && hasRead) {
      return [];
    }
    
    // Apply AND logic - filter books that match ALL selected criteria
    filtered = filtered.where((book) {
      // Check Read/Unread filter (mutually exclusive, so only one can be true at a time)
      if (hasRead && !book.isReadByMe) {
        return false;
      }
      if (hasUnread && book.isReadByMe) {
        return false;
      }
      
      // Check In Circle filter
      if (hasInCircle && !book.isReadByOthers) {
        return false;
      }
      
      // Book satisfies all selected filters
      return true;
    }).toList();
    
    return _applySorting(filtered);
  }
  
  List<Book> _applySorting(List<Book> books) {
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final isAscending = libraryProvider.isAscending;
    
    List<Book> sorted = List.from(books);
    switch (_currentSort) {
      case SortOption.recent:
        // Sort by ID (proxy for created_at - higher ID = more recent)
        sorted.sort((a, b) {
          final comparison = (a.id ?? 0).compareTo(b.id ?? 0);
          return isAscending ? comparison : -comparison;
        });
        break;
      case SortOption.rating:
        sorted.sort((a, b) {
          final aRating = a.averageRating ?? 0.0;
          final bRating = b.averageRating ?? 0.0;
          final comparison = aRating.compareTo(bRating);
          return isAscending ? comparison : -comparison;
        });
        break;
      case SortOption.pages:
        sorted.sort((a, b) {
          final comparison = a.totalPages.compareTo(b.totalPages);
          return isAscending ? comparison : -comparison;
        });
        break;
      case SortOption.title:
        sorted.sort((a, b) {
          final comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          return isAscending ? comparison : -comparison;
        });
        break;
    }
    
    return sorted;
  }

  Widget _buildFloatingFilterBar(BuildContext context, AppLocalizations l10n, List<Book> filteredBooks) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapse/Expand header
          InkWell(
              onTap: () {
                setState(() {
                  _isFilterBarExpanded = !_isFilterBarExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _isFilterBarExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.deltaTeal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search & Filter',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.deltaTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!_isFilterBarExpanded && _searchQuery.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.deltaTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Search: $_searchQuery',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.deltaTeal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (!_isFilterBarExpanded && _activeFilters.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldLeaf.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_activeFilters.length} filter${_activeFilters.length > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.goldLeaf,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // Expandable content - instant visibility toggle
          if (_isFilterBarExpanded)
            Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: l10n.searchBooks,
                        prefixIcon: Icon(Icons.search, color: AppColors.deltaTeal),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: AppColors.deltaTeal),
                                onPressed: _clearSearch,
                                tooltip: 'Clear',
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.riverMist.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.riverMist, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.deltaTeal, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  // Sort options
                  _buildSortOptions(context, l10n),
                  // Filter chips
                  _buildFilterChips(context, l10n, filteredBooks),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildSortOptions(BuildContext context, AppLocalizations l10n) {
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.riverMist.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: AppColors.riverMist, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sort By',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.deltaTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSortChip(context, 'New', SortOption.recent, Icons.access_time, libraryProvider),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSortChip(context, 'Stars', SortOption.rating, Icons.star, libraryProvider),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSortChip(context, 'Size', SortOption.pages, Icons.menu_book, libraryProvider),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSortChip(context, 'Name', SortOption.title, Icons.sort_by_alpha, libraryProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    String label,
    SortOption option,
    IconData icon,
    LibraryProvider libraryProvider,
  ) {
    return Consumer<LibraryProvider>(
      builder: (context, provider, _) {
        final isSelected = _currentSort == option;
        return InkWell(
          onTap: () {
            if (_currentSort == option) {
              // Toggle sort direction when clicking an already selected chip
              provider.toggleSortDirection();
            } else {
              // Select new sort option
              setState(() {
                _currentSort = option;
              });
            }
            _resetScrollPosition();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.deepSeaBlue
                  : AppColors.riverMist.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.deepSeaBlue : AppColors.riverMist,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.deltaTeal,
                ),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.deltaTeal,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 3),
                  Icon(
                    provider.isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(BuildContext context, AppLocalizations l10n, List<Book> filteredBooks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Unread filter
            FilterChip(
              label: const Text('Unread'),
              selected: _activeFilters.contains(FilterOption.unread),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _activeFilters.add(FilterOption.unread);
                  } else {
                    _activeFilters.remove(FilterOption.unread);
                  }
                });
                _resetScrollPosition();
              },
              selectedColor: AppColors.deepSeaBlue.withOpacity(0.2),
              checkmarkColor: AppColors.deepSeaBlue,
              labelStyle: TextStyle(
                color: _activeFilters.contains(FilterOption.unread)
                    ? AppColors.deepSeaBlue 
                    : AppColors.deltaTeal,
                fontWeight: _activeFilters.contains(FilterOption.unread)
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            // Read filter
            FilterChip(
              label: const Text('Read'),
              selected: _activeFilters.contains(FilterOption.read),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _activeFilters.add(FilterOption.read);
                  } else {
                    _activeFilters.remove(FilterOption.read);
                  }
                });
                _resetScrollPosition();
              },
              selectedColor: AppColors.goldLeaf.withOpacity(0.2),
              checkmarkColor: AppColors.goldLeaf,
              labelStyle: TextStyle(
                color: _activeFilters.contains(FilterOption.read)
                    ? AppColors.goldLeaf 
                    : AppColors.deltaTeal,
                fontWeight: _activeFilters.contains(FilterOption.read)
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            // In Circle filter
            FilterChip(
              label: const Text('In Circle'),
              selected: _activeFilters.contains(FilterOption.inCircle),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _activeFilters.add(FilterOption.inCircle);
                  } else {
                    _activeFilters.remove(FilterOption.inCircle);
                  }
                });
                _resetScrollPosition();
              },
              selectedColor: AppColors.deepSeaBlue.withOpacity(0.2),
              checkmarkColor: AppColors.deepSeaBlue,
              labelStyle: TextStyle(
                color: _activeFilters.contains(FilterOption.inCircle)
                    ? AppColors.deepSeaBlue 
                    : AppColors.deltaTeal,
                fontWeight: _activeFilters.contains(FilterOption.inCircle)
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            // Surprise Me button
            FilterChip(
              avatar: const Icon(Icons.shuffle, size: 18),
              label: const Text('Surprise Me'),
              selected: false,
              onSelected: (selected) {
                _surpriseMe(context, filteredBooks);
              },
              backgroundColor: AppColors.goldLeaf.withOpacity(0.1),
              selectedColor: AppColors.goldLeaf.withOpacity(0.2),
              labelStyle: const TextStyle(
                color: AppColors.goldLeaf,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _surpriseMe(BuildContext context, List<Book> books) {
    // Filter to unread books only
    final unreadBooks = books.where((book) => !book.isReadByMe).toList();
    
    if (unreadBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No unread books available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Pick a random unread book
    final random = Random();
    final randomBook = unreadBooks[random.nextInt(unreadBooks.length)];
    
    // Navigate to book detail
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final selectedLibrary = libraryProvider.selectedLibrary;
    
    if (selectedLibrary != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetailScreen(
            book: randomBook,
            libraryId: selectedLibrary.id,
          ),
        ),
      ).then((_) {
        if (mounted) {
          libraryProvider.fetchLibraries();
        }
      });
    }
  }

  Future<void> _confirmAndRemoveBookFromLibrary(
      BuildContext context, Book book) async {
    if (book.id == null) return;

    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Book'),
        content: const Text('Remove this book from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.deepSeaBlue,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator while removing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    String? errorMessage;
    try {
      errorMessage = await libraryProvider.removeBook(book.id!);
    } finally {
      Navigator.of(context).pop(); // Close loading dialog
    }

    if (!mounted) return;

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book removed from your library'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Sort Books',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.deltaTeal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildSortOption(
                context,
                'Recent',
                SortOption.recent,
                Icons.access_time,
              ),
              _buildSortOption(
                context,
                'Rating',
                SortOption.rating,
                Icons.star,
              ),
              _buildSortOption(
                context,
                'Pages',
                SortOption.pages,
                Icons.menu_book,
              ),
              _buildSortOption(
                context,
                'Title',
                SortOption.title,
                Icons.sort_by_alpha,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    SortOption option,
    IconData icon,
  ) {
    final isSelected = _currentSort == option;
    
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, _) {
        return ListTile(
          leading: Icon(
            icon,
            color: isSelected ? AppColors.deepSeaBlue : AppColors.textSecondary,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.deepSeaBlue : AppColors.deltaTeal,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check, color: AppColors.deepSeaBlue),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: Icon(
                  libraryProvider.isAscending 
                      ? Icons.arrow_upward 
                      : Icons.arrow_downward,
                  color: AppColors.deepSeaBlue,
                  size: 20,
                ),
                onPressed: () {
                  libraryProvider.toggleSortDirection();
                },
                tooltip: libraryProvider.isAscending 
                    ? 'Ascending' 
                    : 'Descending',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _currentSort = option;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }


  /// Build avatars for other people who have read the book
  /// Uses circle_interactions from backend (which includes all users who read the book)
  List<Widget> _buildOtherReadersAvatars(Book book, int? currentUserId) {
    final Set<int> seenUserIds = {};
    final List<Widget> avatars = [];
    
    // If isReadByOthers is true, we MUST show avatars
    if (!book.isReadByOthers) {
      return avatars;
    }
    
    // Use circle_interactions from backend - this contains all users who have read the book
    if (book.circleInteractions.isNotEmpty) {
      for (final interaction in book.circleInteractions) {
        final userId = interaction.userId;
        if (userId != currentUserId && !seenUserIds.contains(userId) && interaction.isRead) {
          seenUserIds.add(userId);
          avatars.add(
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: UserAvatar(
                firstName: interaction.firstName,
                lastName: interaction.lastName,
                email: null, // Email not provided in circle_interactions
                size: 24,
                fallbackText: '?',
              ),
            ),
          );
        }
      }
    }
    
    return avatars;
  }

}
