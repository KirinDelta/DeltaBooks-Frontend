import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../providers/library_provider.dart';
import '../models/book.dart';
import '../models/library.dart';
import '../theme/app_colors.dart';

class BookEditScreen extends StatefulWidget {
  final Book? initialBook;

  const BookEditScreen({
    super.key,
    this.initialBook,
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
    _selectedLibrary = libraryProvider.selectedLibrary;
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
            
            // Series Name
            TextFormField(
              controller: _seriesNameController,
              decoration: InputDecoration(
                labelText: 'Series Name (${l10n.optional.toLowerCase()})',
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
            const SizedBox(height: 24),
            
            // Library selection
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
            
            // Library-specific total pages override
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
            const SizedBox(height: 24),
            
            // Add button
            ElevatedButton.icon(
              onPressed: _isAdding ? null : _addToLibrary,
              icon: _isAdding
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_isAdding ? l10n.searching : l10n.addToLibrary),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldLeaf,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        title: Text(l10n.createManually),
      ),
      body: SafeArea(
        child: _buildEditForm(),
      ),
    );
  }
}
