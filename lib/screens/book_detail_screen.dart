import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/book_comment.dart';
import '../models/library.dart';
import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/mark_as_read_sheet.dart';
import '../widgets/user_avatar.dart';
import 'book_edit_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final int? libraryId; // Optional - null means search preview mode
  final bool isSearchPreview; // Show OWNED badge only in search preview

  const BookDetailScreen({
    super.key,
    required this.book,
    this.libraryId,
    this.isSearchPreview = false,
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
    // Store provider reference and listen to library changes (only if in library mode)
    if (widget.libraryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
          _libraryProvider?.addListener(_onLibraryChanged);
          // Force-refresh this library's details so currentUserPermissions is
          // up to date before we evaluate delete permissions.
          _libraryProvider?.fetchLibraryDetails(book.libraryId);
        }
      });
    }
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

  Future<void> _confirmAndRemoveBook(BuildContext context) async {
    if (!mounted || widget.libraryId == null || book.id == null) return;

    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);

    // Confirmation dialog
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

    if (confirmed != true || !mounted) return;

    // Show a loading indicator while removing the book
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    String? errorMessage;
    try {
      errorMessage = await libraryProvider.removeBook(book.id!);
    } finally {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
    }

    if (!mounted) return;

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book removed from your library'),
        ),
      );
      // Refresh libraries so the main list view removes the book.
      await libraryProvider.refreshLibrary();
      if (!mounted) return;
      // Pop back to the library screen after successful removal
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  void _showMarkAsReadSheet(BuildContext context) {
    if (!mounted || widget.libraryId == null) return;
    
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
          libraryId: widget.libraryId!,
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
    if (!mounted || widget.libraryId == null) return;
    
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
        libraryId: widget.libraryId!,
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

  Future<void> _addBookToLibrary(BuildContext context) async {
    if (!mounted) return;
    
    // Navigate to BookEditScreen with the book as initialBook
    // This allows the user to edit fields (pages, price, etc.) before adding
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookEditScreen(
          initialBook: book,
        ),
      ),
    );
    
    // If book was added, navigate back and refresh libraries
    if (result == true && mounted) {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      await libraryProvider.fetchLibraries();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final libraryProvider = context.watch<LibraryProvider>();

    // Use new backend fields
    final hasRead = book.isReadByMe;

    // Resolve the active library context from the provider.
    final Library? library = libraryProvider.currentLibrary;

    // Check if the current user is the owner (string comparison for safety).
    final bool isOwner =
        library?.ownerId?.toString() == authProvider.userId?.toString();

    // Check if the current user is a partner with explicit remove permission.
    final bool canRemoveAsPartner =
        library?.permissions?['can_remove'] == true;

    // Final flag controlling whether the delete button is shown.
    final bool canDelete = isOwner || canRemoveAsPartner;

    // Debug log to verify IDs and permission resolution.
    // ignore: avoid_print
    print(
        'DEBUG: OwnerID: ${library?.ownerId}, UserID: ${authProvider.userId}, hasPermission: $canRemoveAsPartner');

    return Scaffold(
      appBar: AppBar(
        title: widget.libraryId == null && widget.isSearchPreview
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppImages.logo,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.bookDetails),
                ],
              )
            : Text(l10n.bookDetails),
        backgroundColor: AppColors.deepSeaBlue,
        foregroundColor: Colors.white,
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              color: Colors.white,
              onPressed: () => _confirmAndRemoveBook(context),
              tooltip: 'Remove Book',
            ),
        ],
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
                  // Title with read badge and owned badge (if search preview)
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
                      const SizedBox(width: 8),
                      // OWNED badge (only in search preview mode)
                      if (widget.isSearchPreview && book.isOwnedGlobally)
                        Container(
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
                            l10n.owned,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                      if (widget.isSearchPreview && book.isOwnedGlobally)
                        const SizedBox(width: 8),
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
                  
                  // Genre badge (if available)
                  if (book.genre != null && book.genre!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.riverMist,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        book.genre!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.deltaTeal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Series Name (if available)
                  if (book.seriesName != null && book.seriesName!.isNotEmpty) ...[
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.deltaTeal,
                        ),
                        children: [
                          const TextSpan(text: 'Series: '),
                          TextSpan(
                            text: book.seriesName!,
                            style: TextStyle(
                              color: AppColors.goldLeaf,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
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
                  
                  // Library mode: Show status cards and comments (only if libraryId is not null)
                  if (widget.libraryId != null) ...[
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
                  ], // Close widget.libraryId != null block
                  
                  // Add book button (only in search preview mode)
                  if (widget.isSearchPreview && widget.libraryId == null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _addBookToLibrary(context),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addToLibrary),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldLeaf,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
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
