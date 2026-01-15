import 'package:flutter/material.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../models/book.dart';
import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import 'book_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final List<Book> books;
  final String searchQuery;

  const SearchResultsScreen({
    super.key,
    required this.books,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
        backgroundColor: AppColors.deepSeaBlue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.white,
      body: books.isEmpty
          ? Stack(
              children: [
                Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset(
                      AppImages.logo,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noResults,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.deltaTeal,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return _buildBookCard(context, book);
              },
            ),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    // Apply desaturation if book is owned globally
    final isOwned = book.isOwnedGlobally;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 12,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Desaturation effect using ColorFilter - slight desaturation (about 30%)
          ColorFiltered(
            colorFilter: isOwned 
                ? const ColorFilter.matrix([
                    0.75, 0.15, 0.1, 0, 0,  // Red channel - slight desaturation
                    0.15, 0.75, 0.1, 0, 0,  // Green channel
                    0.1,  0.1,  0.8, 0, 0,  // Blue channel
                    0,    0,    0,   1, 0,  // Alpha channel - keep opacity
                  ])
                : const ColorFilter.mode(Colors.transparent, BlendMode.color),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                // Navigate to preview (BookDetailScreen with isSearchPreview: true)
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(
                      book: book,
                      isSearchPreview: true,
                    ),
                  ),
                );
                
                // If book was added, pop back to manual entry screen
                if (result == true) {
                  Navigator.pop(context, true);
                }
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  top: 16,
                  bottom: 16,
                  right: isOwned ? 80 : 16, // Add extra right padding when badge is present
                ),
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
                        // Sub-Cover Metadata
                        if (book.totalPages > 0) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 60,
                            child: Row(
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
                                          color: AppColors.textTertiary,
                                          fontSize: 10,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Middle: Expanded Column with Title, Author, Rating
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
                          const SizedBox(height: 8),
                          // Star Rating
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
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // OWNED badge in top-right corner
          if (isOwned)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldLeaf,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ],
                ),
                child: Text(
                  AppLocalizations.of(context)!.owned,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
