import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/library.dart';
import '../providers/book_provider.dart';
import '../providers/library_provider.dart';
import '../providers/wishlist_provider.dart';
import '../theme/app_colors.dart';
import '../utils/image_utils.dart';

class AddBookConfirmationScreen extends StatefulWidget {
  final Book book;

  const AddBookConfirmationScreen({super.key, required this.book});

  @override
  State<AddBookConfirmationScreen> createState() =>
      _AddBookConfirmationScreenState();
}

class _AddBookConfirmationScreenState
    extends State<AddBookConfirmationScreen> {
  int? _selectedLibraryId;
  bool _addToWishlist = false;
  String _status = 'unread';
  bool _isAdding = false;

  bool get _canAdd => _addToWishlist || _selectedLibraryId != null;

  void _selectLibrary(int id) {
    setState(() {
      _selectedLibraryId = id;
      _addToWishlist = false;
    });
  }

  void _selectWishlist() {
    setState(() {
      _selectedLibraryId = null;
      _addToWishlist = true;
    });
  }

  Future<void> _add() async {
    if (!_canAdd || _isAdding) return;

    final l10n = AppLocalizations.of(context)!;
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);

    setState(() => _isAdding = true);

    try {
      if (_addToWishlist) {
        final bookId = widget.book.id;
        if (bookId == null) return;
        if (wishlistProvider.isWishlisted(bookId)) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.alreadyInWishlist)));
          return;
        }
        final ok = await wishlistProvider.addToWishlist(bookId);
        if (!mounted) return;
        if (ok) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.addError)));
        }
      } else {
        final libraryId = _selectedLibraryId!;
        await bookProvider.addBookToLibrary(
          bookId: widget.book.id,
          isbn: widget.book.isbn.isNotEmpty ? widget.book.isbn : null,
          title: widget.book.title.isNotEmpty ? widget.book.title : null,
          author: widget.book.author.isNotEmpty ? widget.book.author : null,
          coverUrl: widget.book.coverUrl,
          totalPages:
              widget.book.totalPages > 0 ? widget.book.totalPages : null,
          description: widget.book.description,
          genre: widget.book.genre,
          seriesName: widget.book.seriesName,
          libraryId: libraryId,
        );
        if (_status != 'unread') {
          await bookProvider.setBookStatus(
            bookId: widget.book.id!,
            libraryId: libraryId,
            status: _status,
          );
        }
        await libraryProvider.fetchLibraries();
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.addError)));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allLibraries = context.watch<LibraryProvider>().allLibraries;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addBook),
        backgroundColor: AppColors.deepSeaBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBookPreview(context),
                  const SizedBox(height: 32),
                  Text(
                    l10n.addTo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.deltaTeal,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildDestinationChips(context, allLibraries, l10n),
                  if (_selectedLibraryId != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.readingStatus,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.deltaTeal,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusChips(context, l10n),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canAdd && !_isAdding ? _add : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canAdd ? AppColors.goldLeaf : Colors.grey[300],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAdding
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        l10n.add,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookPreview(BuildContext context) {
    final book = widget.book;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: book.coverUrl != null
              ? Image.network(
                  proxiedCoverUrl(book.coverUrl)!,
                  width: 72,
                  height: 108,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _bookPlaceholder(),
                )
              : _bookPlaceholder(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deltaTeal,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                book.author,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (book.totalPages > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${book.totalPages} pages',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _bookPlaceholder() {
    return Container(
      width: 72,
      height: 108,
      decoration: BoxDecoration(
        color: AppColors.riverMist,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.book, color: AppColors.textTertiary, size: 32),
    );
  }

  Widget _buildDestinationChips(
    BuildContext context,
    List<Library> allLibraries,
    AppLocalizations l10n,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...allLibraries.map((library) {
          final isSelected = _selectedLibraryId == library.id;
          return ChoiceChip(
            label: Text(library.name),
            selected: isSelected,
            onSelected: (_) => _selectLibrary(library.id),
            selectedColor: AppColors.deepSeaBlue,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.deltaTeal,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            avatar: Icon(
              library.isOwner ? Icons.library_books : Icons.people,
              size: 16,
              color: isSelected ? Colors.white : AppColors.deltaTeal,
            ),
          );
        }),
        ChoiceChip(
          label: Text(l10n.wishlist),
          selected: _addToWishlist,
          onSelected: (_) => _selectWishlist(),
          selectedColor: AppColors.deepSeaBlue,
          labelStyle: TextStyle(
            color: _addToWishlist ? Colors.white : AppColors.deltaTeal,
            fontWeight:
                _addToWishlist ? FontWeight.w600 : FontWeight.normal,
          ),
          avatar: Icon(
            Icons.bookmark_border,
            size: 16,
            color: _addToWishlist ? Colors.white : AppColors.deltaTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips(BuildContext context, AppLocalizations l10n) {
    final statuses = [
      ('unread', l10n.unread, Icons.radio_button_unchecked),
      ('reading', l10n.reading, Icons.auto_stories),
      ('finished', l10n.finished, Icons.check_circle_outline),
    ];
    return Wrap(
      spacing: 8,
      children: statuses.map((s) {
        final isSelected = _status == s.$1;
        return ChoiceChip(
          label: Text(s.$2),
          selected: isSelected,
          onSelected: (_) => setState(() => _status = s.$1),
          selectedColor: AppColors.goldLeaf,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.deltaTeal,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          avatar: Icon(
            s.$3,
            size: 16,
            color: isSelected ? Colors.white : AppColors.deltaTeal,
          ),
        );
      }).toList(),
    );
  }
}
