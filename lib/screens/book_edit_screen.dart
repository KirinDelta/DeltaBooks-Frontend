import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../providers/library_provider.dart';
import '../models/book.dart';
import '../models/library.dart';
import '../theme/app_colors.dart';
import '../theme/app_images.dart';

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
  Library? _selectedLibrary;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    if (widget.initialBook != null) {
      _currentBook = widget.initialBook;
      _populateForm(widget.initialBook!);
    }
    
    // Load selected library
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    if (widget.editMode && widget.libraryId != null) {
      // In edit mode, use the libraryId passed in
      _selectedLibrary = libraryProvider.getLibraryById(widget.libraryId);
    } else {
      // In add mode, use the currently selected library
      _selectedLibrary = libraryProvider.selectedLibrary;
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
    // Populate series name and volume from combined data (prioritizing override)
    _seriesNameController.text = book.seriesName ?? '';
    _seriesVolumeController.text = book.seriesVolume ?? '';
    // Populate notes from book model
    _notesController.text = book.notes ?? '';
    // Populate price from book model
    if (book.price != null) {
      // Format price to remove unnecessary decimal places (e.g., 29.0 -> 29, 29.99 -> 29.99)
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

  Future<void> _addToLibrary() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLibrary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectLibraryFirst)),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      
      // Parse form values
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
        libraryId: _selectedLibrary!.id,
      );

      if (mounted) {
        if (result != null) {
          // Refresh libraries
          final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
          await libraryProvider.fetchLibraries();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bookAdded)),
          );
          
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.addError)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _updateBook() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.libraryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid book or library: Library ID is missing')),
      );
      return;
    }

    // Determine the library_book_id to use for the update
    // In library context, the API might return 'id' as the library_book_id
    // Try libraryBookId first, then fall back to book id if libraryBookId is null
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
      
      // Parse all form values for full metadata editing
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
      
      // Include all fields that can be updated
      if (isbn.isNotEmpty) {
        updateData['isbn'] = isbn;
      }
      if (title.isNotEmpty) {
        updateData['title'] = title;
      }
      if (author.isNotEmpty) {
        updateData['author'] = author;
      }
      if (genre.isNotEmpty) {
        updateData['genre'] = genre;
      } else {
        // Allow clearing by sending empty string
        updateData['genre'] = '';
      }
      if (totalPages > 0) {
        updateData['total_pages'] = totalPages;
      }
      if (description.isNotEmpty) {
        updateData['description'] = description;
      } else {
        // Allow clearing by sending empty string
        updateData['description'] = '';
      }
      if (coverUrl.isNotEmpty) {
        updateData['cover_url'] = coverUrl;
      } else {
        // Allow clearing by sending empty string
        updateData['cover_url'] = '';
      }
      // Send 'series' (not 'series_name') - provider will map it to 'series_name'
      if (seriesName.isNotEmpty) {
        updateData['series'] = seriesName;
      } else {
        // Allow clearing by sending empty string
        updateData['series'] = '';
      }
      // Send 'seriesVolume' - provider will map it to 'series_volume'
      if (seriesVolume.isNotEmpty) {
        updateData['seriesVolume'] = seriesVolume;
      } else {
        // Allow clearing by sending empty string
        updateData['seriesVolume'] = '';
      }
      // Send 'notes' - provider will pass it through as 'notes'
      if (notes.isNotEmpty) {
        updateData['notes'] = notes;
      } else {
        // Allow clearing by sending empty string
        updateData['notes'] = '';
      }
      
      // Send 'price' - library-specific price
      if (price != null) {
        updateData['price'] = price;
      }

      final result = await bookProvider.updateLibraryBook(
        libraryId: widget.libraryId!.toString(),
        bookId: libraryBookId.toString(),
        data: updateData,
      );

      if (mounted) {
        if (result != null) {
          // Create updated Book object with all updated values for immediate UI feedback
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
          
          // Update local Book object in LibraryProvider for immediate UI feedback
          final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
          libraryProvider.updateBookInSelectedLibrary(_currentBook!.id!, updatedBook);
          
          // Refresh libraries and library details to get updated book data from server
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
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Widget _buildCoverPreview() {
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
            AppLocalizations.of(context)!.noCoverImage,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        coverUrl,
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

    // Find the matching library from allLibraries by ID to ensure reference equality
    Library? matchingSelectedLibrary;
    if (_selectedLibrary != null) {
      try {
        matchingSelectedLibrary = allLibraries.firstWhere(
          (lib) => lib.id == _selectedLibrary!.id,
        );
      } catch (e) {
        // Library not found in allLibraries, keep it as null
        matchingSelectedLibrary = null;
      }
    }

    // Check if user has permissions for the selected library
    // Use matchingSelectedLibrary if available, otherwise fall back to _selectedLibrary
    final Library? libraryForPermissions = matchingSelectedLibrary ?? _selectedLibrary;
    final bool isOwner = libraryForPermissions?.isOwner ?? false;
    final bool canAddBooks = libraryForPermissions?.canAddBooks ?? false;
    final bool hasPermissions = isOwner || canAddBooks;
    final bool librarySelected = libraryForPermissions != null;
    
    // Check if required form fields are filled (basic validation check)
    final bool formFieldsValid = _isbnController.text.trim().isNotEmpty &&
        _titleController.text.trim().isNotEmpty &&
        _authorController.text.trim().isNotEmpty &&
        _totalPagesController.text.trim().isNotEmpty;

    // Button enabled if: form valid, library selected, has permissions, and not adding
    // In edit mode, library selection is not needed (already set)
    final bool isAddEnabled = !_isAdding && 
        formFieldsValid && 
        (widget.editMode ? true : librarySelected) && 
        (widget.editMode ? true : hasPermissions);

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
            const SizedBox(height: 24),
            
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
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}), // Trigger rebuild for button state
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
              ),
              onChanged: (_) => setState(() {}), // Trigger rebuild for button state
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
              ),
              onChanged: (_) => setState(() {}), // Trigger rebuild for button state
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.authorRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Cover URL
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
              onChanged: (_) => setState(() {}), // Refresh cover preview
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
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}), // Trigger rebuild for button state
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
              ),
              style: const TextStyle(color: AppColors.deltaTeal),
            ),
            const SizedBox(height: 16),
            
            // Series Name (library-specific override)
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
              ),
              style: const TextStyle(color: AppColors.deltaTeal),
            ),
            const SizedBox(height: 16),
            
            // Series Volume (library-specific)
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
              ),
            ),
            const SizedBox(height: 24),
            
            // Library selection (disabled in edit mode)
            if (!widget.editMode) ...[
              Text(
                l10n.selectLibrary,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Library>(
                value: matchingSelectedLibrary,
                decoration: InputDecoration(
                  labelText: l10n.library,
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
                onChanged: (Library? library) {
                  setState(() {
                    _selectedLibrary = library;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return l10n.selectLibraryFirst;
                  }
                  return null;
                },
              ),
            ] else ...[
              // Show current library in edit mode (disabled/display only)
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
                onChanged: null, // Disabled in edit mode
              ),
            ],
            // Show warning if library selected but user doesn't have permissions
            if (librarySelected && !hasPermissions)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "You don't have permission to add books to this shared library.",
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Price (library-specific)
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
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
            
            // Library-specific total pages override (only shown when adding, not editing)
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
            
            // Notes (library-specific)
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
            
            // Add/Update button
            ElevatedButton(
              onPressed: widget.editMode
                  ? (_isAdding ? null : _updateBook)
                  : (isAddEnabled ? _addToLibrary : null),
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
                    SizedBox(
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
                    Icon(widget.editMode ? Icons.update : Icons.add, size: 20),
                  ],
                  const SizedBox(width: 8),
                  Text(widget.editMode
                      ? (_isAdding ? 'Updating...' : 'Update Book')
                      : (_isAdding ? l10n.searching : l10n.addToLibrary)),
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
