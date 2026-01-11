import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/book_comment.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/mark_as_read_sheet.dart';
import '../widgets/user_avatar.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final int libraryId;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.libraryId,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _currentBook;
  LibraryProvider? _libraryProvider;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    // Store provider reference and listen to library changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
        _libraryProvider?.addListener(_onLibraryChanged);
      }
    });
  }

  @override
  void dispose() {
    // Remove listener if provider is still available
    _libraryProvider?.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    // Only update if widget is still mounted
    if (!mounted) return;
    
    // Update book data when library changes
    final libraryProvider = _libraryProvider;
    if (libraryProvider == null) return;
    
    final selectedLibrary = libraryProvider.selectedLibrary;
    if (selectedLibrary != null) {
      try {
        final updatedBook = selectedLibrary.books.firstWhere(
          (b) => b.id == widget.book.id,
        );
        if (mounted) {
          setState(() {
            _currentBook = updatedBook;
          });
        }
      } catch (e) {
        // Book not found in updated library, keep current book
      }
    }
  }

  Book get book => _currentBook ?? widget.book;

  void _showMarkAsReadSheet(BuildContext context) {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => MarkAsReadSheet(
          book: book,
          libraryId: widget.libraryId,
        ),
      ),
    ).then((shouldRefresh) {
      // Use a post-frame callback to ensure context is valid
      if (shouldRefresh == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Refresh the library to update the book data
            final libraryProvider = _libraryProvider;
            if (libraryProvider != null) {
              libraryProvider.fetchLibraries().then((_) {
                // Update local book state after refresh
                if (mounted) {
                  _onLibraryChanged();
                }
              });
            }
          }
        });
      }
    });
  }

  Future<void> _markAsUnread(BuildContext context) async {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final libraryProvider = _libraryProvider ?? Provider.of<LibraryProvider>(context, listen: false);
    
    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.markAsUnread),
        content: Text(l10n.confirmUnread),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepSeaBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await bookProvider.markBookAsUnread(
        bookId: book.id!,
        libraryId: widget.libraryId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (success) {
        // Refresh libraries to get updated book data
        await libraryProvider.fetchLibraries();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookMarkedAsUnread)),
        );
        
        // Pop the detail screen to go back to library
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMarkingUnread)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMarkingUnread)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context);
    
    // Use new backend fields
    final hasRead = book.isReadByMe;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookDetails),
        backgroundColor: AppColors.deepSeaBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image
            Container(
              width: double.infinity,
              height: 300,
              color: AppColors.riverMist,
              child: book.coverUrl != null
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.book,
                          size: 80,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.book,
                        size: 80,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with read badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          book.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deltaTeal,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: hasRead,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.goldLeaf,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Read',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Author
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Rating and comments - always show stars, even if rating is 0
                  Row(
                    children: [
                      // Star rating using average_rating
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
                          size: 24,
                        );
                      }),
                      if (book.averageRating != null && book.averageRating! > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          book.averageRating!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.deltaTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(width: 16),
                      // Comments count
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: AppColors.deltaTeal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${book.totalCommentsCount} ${l10n.comments}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.deltaTeal,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Book details
                  _buildDetailRow(context, l10n.isbn, book.isbn),
                  if (book.totalPages > 0)
                    _buildDetailRow(context, l10n.pages, book.totalPages.toString()),
                  
                  if (book.description != null && book.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.deltaTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.deltaTeal,
                      ),
                    ),
                  ],
                  
                  // My Status card (if user has read it)
                  if (hasRead) ...[
                    const SizedBox(height: 24),
                    _buildMyStatusCard(context, authProvider),
                  ],
                  
                  // Floating action button for Mark as Read (if user hasn't read it)
                  if (!hasRead) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showMarkAsReadSheet(context),
                        icon: const Icon(Icons.check_circle),
                        label: Text(l10n.markAsRead),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldLeaf,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                  
                  // Comments section - display all comments from all users
                  if (book.comments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Comments (${book.comments.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.deltaTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...book.comments.map((comment) {
                      final isCurrentUser = authProvider.user?.id == comment.user.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCommentCard(
                          context,
                          comment: comment,
                          isCurrentUser: isCurrentUser,
                        ),
                      );
                    }),
                    // Add bottom padding to ensure comments are never obscured
                    const SizedBox(height: 20),
                  ] else if (book.totalCommentsCount > 0) ...[
                    // Show message if there are comments but they're not loaded
                    const SizedBox(height: 24),
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.deltaTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${book.totalCommentsCount} comment${book.totalCommentsCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(
    BuildContext context, {
    required BookComment comment,
    required bool isCurrentUser,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.deepSeaBlue.withOpacity(0.1) : AppColors.riverMist,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? AppColors.deepSeaBlue : AppColors.borderLight,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                firstName: comment.user.firstName,
                lastName: comment.user.lastName,
                email: comment.user.email,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCurrentUser ? 'You' : comment.user.email,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.deltaTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Display rating if available
              if (comment.rating != null) ...[
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.goldLeaf),
                    const SizedBox(width: 2),
                    Text(
                      '${comment.rating}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.deltaTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _formatDate(comment.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.deltaTeal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.deltaTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build My Status card showing user's avatar, rating, and Unread button
  Widget _buildMyStatusCard(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.riverMist,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Status',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.deltaTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // User avatar
              UserAvatar(
                firstName: user?.firstName,
                lastName: user?.lastName,
                email: user?.email,
                size: 40,
              ),
              const SizedBox(width: 12),
              // Rating and Unread button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating stars
                    if (book.myRating != null && book.myRating! > 0)
                      Row(
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          return Icon(
                            starIndex <= book.myRating!
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.goldLeaf,
                            size: 18,
                          );
                        }),
                      )
                    else
                      Text(
                        'No rating',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Unread button
                    OutlinedButton(
                      onPressed: () => _markAsUnread(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.deepSeaBlue,
                        side: const BorderSide(color: AppColors.deepSeaBlue, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Unread'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Comment text if available
          if (book.myComment != null && book.myComment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              book.myComment!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.deltaTeal,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
