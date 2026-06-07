import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../services/cloudinary_service.dart';
import '../providers/book_provider.dart';
import '../providers/library_provider.dart';
import '../providers/wishlist_provider.dart';
import '../models/book.dart';
import '../models/library.dart';
import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import '../utils/image_utils.dart';
import '../widgets/barcode_field_button.dart';
import '../widgets/ocr_field_button.dart';

class BookEditScreen extends StatefulWidget {
  final Book? initialBook;
  final int? libraryId;
  final bool editMode;

  const BookEditScreen({
    super.key,
    this.initialBook,
    this.libraryId,
    this.editMode = false,
  });

  @override
  State<BookEditScreen> createState() => _BookEditScreenState();
}

class _BookEditScreenState extends State<BookEditScreen> {
  // Form controllers
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _coverUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _totalPagesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _libraryPagesController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _seriesNameController = TextEditingController();
  final TextEditingController _seriesVolumeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Book? _currentBook;
  bool _isAdding = false;
  bool _isUploadingImage = false;
  // Only used in edit mode to display the current library.
  Library? _selectedLibrary;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.initialBook != null) {
      _currentBook = widget.initialBook;
      _populateForm(widget.initialBook!);
    }

    // In edit mode, resolve the library reference for display.
    if (widget.editMode && widget.libraryId != null) {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      _selectedLibrary = libraryProvider.getLibraryById(widget.libraryId);
    }
  }

  void _populateForm(Book book) {
    _isbnController.text = book.isbn;
    _titleController.text = book.title;
    _authorController.text = book.author;
    _coverUrlController.text = book.coverUrl ?? '';
    _descriptionController.text = book.description ?? '';
    _totalPagesController.text = book.totalPages > 0 ? book.totalPages.toString() : '';
    _genreController.text = book.genre ?? '';
    _seriesNameController.text = book.seriesName ?? '';
    _seriesVolumeController.text = book.seriesVolume ?? '';
    _notesController.text = book.notes ?? '';
    if (book.price != null) {
      final priceStr = book.price!.toStringAsFixed(book.price!.truncateToDouble() == book.price! ? 0 : 2);
      _priceController.text = priceStr;
    } else {
      _priceController.text = '';
    }
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _coverUrlController.dispose();
    _descriptionController.dispose();
    _totalPagesController.dispose();
    _priceController.dispose();
    _libraryPagesController.dispose();
    _genreController.dispose();
    _seriesNameController.dispose();
    _seriesVolumeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Shows the destination picker bottom sheet. Called from the save button in add mode.
  // Returns after the sheet is dismissed; if the user picked a destination the add
  // action runs and the screen pops on success. If the sheet is dismissed without a
  // selection, nothing happens and the user returns to the form with edits intact.
  Future<void> _showDestinationSheet() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final allLibraries =
        Provider.of<LibraryProvider>(context, listen: false).allLibraries;

    int? chosenLibraryId;
    bool chooseWishlist = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Text(
                  l10n.addBook,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.deltaTeal,
                      ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...allLibraries.map((library) {
                      return ListTile(
                        leading: Icon(
                          library.isOwner ? Icons.library_books : Icons.people,
                          color: AppColors.deltaTeal,
                        ),
                        title: Text(library.name),
                        onTap: () {
                          chosenLibraryId = library.id;
                          Navigator.pop(sheetContext);
                        },
                      );
                    }),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.bookmark_border,
                        color: AppColors.deltaTeal,
                      ),
                      title: Text(l10n.addToWishlist),
                      // Wishlist requires the book to already exist in the backend.
                      // When the book was looked up via ISBN/search, it has an id.
                      // For fully manual entries (no lookup), the wishlist option is disabled.
                      enabled: _currentBook?.id != null,
                      onTap: _currentBook?.id == null
                          ? null
                          : () {
                              chooseWishlist = true;
                              Navigator.pop(sheetContext);
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (chosenLibraryId != null) {
      await _addToLibrary(chosenLibraryId!);
    } else if (chooseWishlist) {
      await _addToWishlist();
    }
    // Dismissed without selection — do nothing (edits intact).
  }

  Future<void> _addToLibrary(int libraryId) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isAdding = true);

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);

      final isbn = _isbnController.text.trim();
      final title = _titleController.text.trim();
      final author = _authorController.text.trim();
      final coverUrl = _coverUrlController.text.trim();
      final description = _descriptionController.text.trim();
      final totalPages = int.tryParse(_totalPagesController.text.trim()) ?? 0;
      final price = double.tryParse(_priceController.text.trim());
      final libraryTotalPages = int.tryParse(_libraryPagesController.text.trim());
      final genre = _genreController.text.trim();
      final seriesName = _seriesNameController.text.trim();

      final result = await bookProvider.addBookToLibrary(
        bookId: _currentBook?.id,
        isbn: isbn.isNotEmpty ? isbn : null,
        title: title.isNotEmpty ? title : null,
        author: author.isNotEmpty ? author : null,
        coverUrl: coverUrl.isNotEmpty ? coverUrl : null,
        totalPages: totalPages > 0 ? totalPages : null,
        description: description.isNotEmpty ? description : null,
        genre: genre.isNotEmpty ? genre : null,
        seriesName: seriesName.isNotEmpty ? seriesName : null,
        price: price,
        libraryTotalPages: libraryTotalPages,
        libraryId: libraryId,
      );

      if (mounted) {
        if (result != null) {
          final libraryProvider =
              Provider.of<LibraryProvider>(context, listen: false);
          await libraryProvider.fetchLibraries();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.bookAdded)));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.addError)));
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = l10n.addError;
        if (e.toString().contains('Failed to add book:')) {
          errorMessage = e.toString().split(': ').skip(1).join(': ');
          if (errorMessage.contains('permission') ||
              errorMessage.contains('Permission')) {
            errorMessage =
                "You don't have permission to add books to this library.";
          }
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _addToWishlist() async {
    final l10n = AppLocalizations.of(context)!;
    final bookId = _currentBook?.id;
    if (bookId == null) return;

    setState(() => _isAdding = true);

    try {
      final wishlistProvider =
          Provider.of<WishlistProvider>(context, listen: false);
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.addError)));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _updateBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.libraryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid book or library: Library ID is missing')),
      );
      return;
    }

    final libraryBookId = _currentBook?.libraryBookId ?? _currentBook?.id;

    if (libraryBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid book or library: Book ID is missing. Please refresh and try again.')),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);

      final isbn = _isbnController.text.trim();
      final title = _titleController.text.trim();
      final author = _authorController.text.trim();
      final genre = _genreController.text.trim();
      final totalPages = int.tryParse(_totalPagesController.text.trim()) ?? 0;
      final description = _descriptionController.text.trim();
      final coverUrl = _coverUrlController.text.trim();
      final seriesName = _seriesNameController.text.trim();
      final seriesVolume = _seriesVolumeController.text.trim();
      final notes = _notesController.text.trim();
      final price = double.tryParse(_priceController.text.trim());

      final updateData = <String, dynamic>{};

      if (isbn.isNotEmpty) updateData['isbn'] = isbn;
      if (title.isNotEmpty) updateData['title'] = title;
      if (author.isNotEmpty) updateData['author'] = author;
      updateData['genre'] = genre.isNotEmpty ? genre : '';
      if (totalPages > 0) updateData['total_pages'] = totalPages;
      updateData['description'] = description.isNotEmpty ? description : '';
      updateData['cover_url'] = coverUrl.isNotEmpty ? coverUrl : '';
      updateData['series'] = seriesName.isNotEmpty ? seriesName : '';
      updateData['seriesVolume'] = seriesVolume.isNotEmpty ? seriesVolume : '';
      updateData['notes'] = notes.isNotEmpty ? notes : '';
      if (price != null) updateData['price'] = price;

      final result = await bookProvider.updateLibraryBook(
        libraryId: widget.libraryId!.toString(),
        bookId: libraryBookId.toString(),
        data: updateData,
      );

      if (mounted) {
        if (result != null) {
          final updatedBook = Book(
            id: _currentBook!.id,
            libraryId: _currentBook!.libraryId,
            libraryBookId: _currentBook!.libraryBookId,
            isbn: isbn.isNotEmpty ? isbn : _currentBook!.isbn,
            title: title.isNotEmpty ? title : _currentBook!.title,
            author: author.isNotEmpty ? author : _currentBook!.author,
            coverUrl: coverUrl.isNotEmpty ? coverUrl : _currentBook!.coverUrl,
            totalPages: totalPages > 0 ? totalPages : _currentBook!.totalPages,
            description: description.isNotEmpty ? description : _currentBook!.description,
            source: _currentBook!.source,
            genre: genre.isNotEmpty ? genre : _currentBook!.genre,
            seriesName: seriesName.isNotEmpty ? seriesName : _currentBook!.seriesName,
            seriesVolume: seriesVolume.isNotEmpty ? seriesVolume : _currentBook!.seriesVolume,
            notes: notes.isNotEmpty ? notes : _currentBook!.notes,
            price: price ?? _currentBook!.price,
            isReadByMe: _currentBook!.isReadByMe,
            myRating: _currentBook!.myRating,
            myComment: _currentBook!.myComment,
            averageRating: _currentBook!.averageRating,
            totalCommentsCount: _currentBook!.totalCommentsCount,
            isReadByOthers: _currentBook!.isReadByOthers,
            comments: _currentBook!.comments,
            isOwnedGlobally: _currentBook!.isOwnedGlobally,
            permissions: _currentBook!.permissions,
          );

          final libraryProvider =
              Provider.of<LibraryProvider>(context, listen: false);
          libraryProvider.updateBookInSelectedLibrary(_currentBook!.id!, updatedBook);
          await libraryProvider.fetchLibraryDetails(widget.libraryId!);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book updated successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update book')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update book')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final failMessage = AppLocalizations.of(context)!.imageUploadFailed;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;

    setState(() {
      _isUploadingImage = true;
      _coverUrlController.clear();
    });

    final url = await CloudinaryService.uploadImage(file);

    if (!mounted) return;

    if (url != null) {
      setState(() {
        _coverUrlController.text = url;
        _isUploadingImage = false;
      });
    } else {
      setState(() => _isUploadingImage = false);
      messenger.showSnackBar(SnackBar(content: Text(failMessage)));
    }
  }

  Widget _buildCoverPreview() {
    final l10n = AppLocalizations.of(context)!;

    if (_isUploadingImage) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(l10n.uploadingImage, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final coverUrl = _coverUrlController.text.trim();

    if (coverUrl.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            l10n.noCoverImage,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        proxiedCoverUrl(coverUrl)!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.noCoverImage,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditForm() {
    final l10n = AppLocalizations.of(context)!;
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final allLibraries = libraryProvider.allLibraries;

    // In edit mode, resolve a fresh library reference for the display dropdown.
    Library? matchingSelectedLibrary;
    if (widget.editMode && _selectedLibrary != null) {
      try {
        matchingSelectedLibrary = allLibraries.firstWhere(
          (lib) => lib.id == _selectedLibrary!.id,
        );
      } catch (_) {
        matchingSelectedLibrary = null;
      }
    }

    final bool formFieldsValid = _isbnController.text.trim().isNotEmpty &&
        _titleController.text.trim().isNotEmpty &&
        _authorController.text.trim().isNotEmpty &&
        _totalPagesController.text.trim().isNotEmpty;

    // In add mode the library is chosen via the bottom sheet, so no library
    // selection or permission check is needed here.
    final bool isAddEnabled = !_isAdding && !_isUploadingImage && formFieldsValid;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover preview
            Text(
              l10n.coverPreview,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildCoverPreview(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAdding || _isUploadingImage
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(l10n.takePhoto),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepSeaBlue,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAdding || _isUploadingImage
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text(l10n.chooseFromGallery),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepSeaBlue,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ISBN
            TextFormField(
              controller: _isbnController,
              decoration: InputDecoration(
                labelText: '${l10n.isbn} *',
                hintText: l10n.enterIsbn,
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: BarcodeFieldButton(controller: _isbnController),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.isbnRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '${l10n.title} *',
                hintText: l10n.enterTitle,
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: OcrFieldButton(controller: _titleController),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.titleRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Author
            TextFormField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: '${l10n.author} *',
                hintText: l10n.enterAuthor,
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: OcrFieldButton(controller: _authorController),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.authorRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Cover URL
            Text(
              l10n.orEnterUrl,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _coverUrlController,
              decoration: InputDecoration(
                labelText: '${l10n.coverImageUrl} (${l10n.optional.toLowerCase()})',
                hintText: l10n.enterCoverUrl,
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Total Pages
            TextFormField(
              controller: _totalPagesController,
              decoration: InputDecoration(
                labelText: '${l10n.pages} *',
                hintText: '0',
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: OcrFieldButton(
                  controller: _totalPagesController,
                  numericOnly: true,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pagesRequired;
                }
                final pages = int.tryParse(value.trim());
                if (pages == null || pages <= 0) {
                  return l10n.pagesRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '${l10n.description} (${l10n.optional.toLowerCase()})',
                hintText: l10n.enterDescription,
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: OcrFieldButton(
                  controller: _descriptionController,
                  multiLine: true,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Genre
            TextFormField(
              controller: _genreController,
              decoration: InputDecoration(
                labelText: 'Genre (${l10n.optional.toLowerCase()})',
                hintText: 'Enter genre',
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deltaTeal, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                labelStyle: const TextStyle(color: AppColors.deltaTeal),
                suffixIcon: OcrFieldButton(controller: _genreController),
              ),
              style: const TextStyle(color: AppColors.deltaTeal),
            ),
            const SizedBox(height: 16),

            // Series Name
            TextFormField(
              controller: _seriesNameController,
              decoration: InputDecoration(
                labelText: 'Series Name (${l10n.optional.toLowerCase()}, library-specific)',
                hintText: 'Enter series name',
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deltaTeal, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                labelStyle: const TextStyle(color: AppColors.deltaTeal),
                suffixIcon: OcrFieldButton(controller: _seriesNameController),
              ),
              style: const TextStyle(color: AppColors.deltaTeal),
            ),
            const SizedBox(height: 16),

            // Series Volume
            TextFormField(
              controller: _seriesVolumeController,
              decoration: InputDecoration(
                labelText: 'Series Volume (${l10n.optional.toLowerCase()}, library-specific)',
                hintText: 'e.g., Volume 1, Book 2',
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: OcrFieldButton(controller: _seriesVolumeController),
              ),
            ),
            const SizedBox(height: 24),

            // Library display: edit mode only (read-only — destination is fixed).
            if (widget.editMode) ...[
              Text(
                l10n.library,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Library>(
                value: matchingSelectedLibrary,
                decoration: InputDecoration(
                  labelText: l10n.library,
                  filled: true,
                  fillColor: AppColors.riverMist.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: allLibraries.map((library) {
                  final isShared = libraryProvider.isSharedLibrary(library);
                  return DropdownMenuItem<Library>(
                    value: library,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isShared ? Icons.share : Icons.library_books,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            library.name + (isShared ? ' (Shared)' : ''),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: null, // Disabled — library is fixed in edit mode.
              ),
              const SizedBox(height: 16),
            ],

            // Price
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: '${l10n.price} (${l10n.optional.toLowerCase()})',
                hintText: l10n.enterPrice,
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixText: 'RON ',
                suffixIcon: OcrFieldButton(
                  controller: _priceController,
                  decimalAllowed: true,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final price = double.tryParse(value.trim());
                  if (price == null || price < 0) {
                    return l10n.invalidPrice;
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Library-specific total pages override (add mode only)
            if (!widget.editMode) ...[
              TextFormField(
                controller: _libraryPagesController,
                decoration: InputDecoration(
                  labelText: '${l10n.pages} (${l10n.optional.toLowerCase()}, library-specific)',
                  hintText: 'Override total pages for this library',
                  filled: true,
                  fillColor: AppColors.riverMist,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: OcrFieldButton(
                    controller: _libraryPagesController,
                    numericOnly: true,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final pages = int.tryParse(value.trim());
                    if (pages == null || pages <= 0) {
                      return l10n.invalidPages;
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (${l10n.optional.toLowerCase()}, library-specific)',
                hintText: 'Add notes about this book in this library',
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save / Update button
            ElevatedButton(
              onPressed: widget.editMode
                  ? (_isAdding || _isUploadingImage ? null : _updateBook)
                  : (isAddEnabled ? _showDestinationSheet : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.editMode
                    ? (_isAdding ? Colors.grey : AppColors.goldLeaf)
                    : (isAddEnabled ? AppColors.goldLeaf : Colors.grey),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isAdding)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    Image.asset(
                      AppImages.logo,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Icon(widget.editMode ? Icons.update : Icons.check, size: 20),
                  ],
                  const SizedBox(width: 8),
                  Text(widget.editMode
                      ? (_isAdding ? 'Updating...' : 'Update Book')
                      : (_isAdding ? l10n.searching : l10n.save)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editMode ? 'Edit Book' : l10n.createManually),
      ),
      body: SafeArea(
        child: _buildEditForm(),
      ),
    );
  }
}
