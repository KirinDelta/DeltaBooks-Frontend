import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../providers/auth_provider.dart';
import '../models/book.dart';
import '../theme/app_colors.dart';
import '../widgets/mark_as_read_sheet.dart';
import 'book_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int? _lastLibraryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBooks();
    });
  }

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
    
    // Update last library ID to track changes
    if (currentLibraryId != null && currentLibraryId != _lastLibraryId) {
      _lastLibraryId = currentLibraryId;
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

    if (books.isEmpty && !libraryProvider.isLoading) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Text(
                isShared ? l10n.emptyPartnerLibrary : l10n.emptyLibrary,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        itemBuilder: (context, index) {
        final book = books[index];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.user?.id;
        
        // Determine if current user has read it - use new field
        final hasRead = book.isReadByMe;
        final partnerHasRead = book.isReadByOthers;
        
        // Calculate opacity: if I haven't read but partner has, show as unread (lower opacity)
        final opacity = hasRead ? 1.0 : (partnerHasRead ? 0.7 : 1.0);
        
        return Opacity(
          opacity: opacity,
          child: Stack(
            children: [
              // Book card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.riverMist,
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover image with badge overlay
                        Stack(
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
                            // Gold badge if current user has read
                            if (hasRead)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldLeaf,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row with read badge and partner indicator
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      book.title,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.deltaTeal,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Read badge - use Visibility widget for explicit control
                                  Visibility(
                                    visible: hasRead,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.goldLeaf,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'READ',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.author,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Rating and comments row - always show stars, even if rating is 0
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
                              // Note: Individual partner reviews are not available in the book response
                              // The API only provides aggregated data (average_rating, total_comments_count, is_read_by_others)
                              const SizedBox(height: 8),
                              Text(
                                '${l10n.isbn}: ${book.isbn}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              if (book.totalPages > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.page} ${book.totalPages}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ),
              // Partner read indicator - always visible in bottom right corner when partner has read
              if (partnerHasRead)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Tooltip(
                    message: 'Partner read this',
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.deepSeaBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      ),
    );
  }

}
