import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../providers/library_provider.dart';
import '../models/book.dart';
import '../theme/app_colors.dart';
import 'book_edit_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  final String? initialIsbn;

  const ManualEntryScreen({
    super.key,
    this.initialIsbn,
  });

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  
  bool _isSearching = false;
  bool _showTitleAuthorFields = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIsbn != null) {
      _isbnController.text = widget.initialIsbn!;
      // Auto-search if ISBN is provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchByIsbn();
      });
    }
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _searchByIsbn() async {
    final l10n = AppLocalizations.of(context)!;
    final isbn = _isbnController.text.trim();
    
    if (isbn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterIsbnError)),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final book = await bookProvider.searchBooks(isbn: isbn);
      
      if (mounted) {
        if (book != null) {
          // Navigate to BookEditScreen with found book
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookEditScreen(
                initialBook: book,
              ),
            ),
          );
          
          // Refresh libraries if book was added
          if (result == true && mounted) {
            final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
            await libraryProvider.fetchLibraries();
            Navigator.pop(context, true);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bookNotFound)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.searchError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _searchByTitleAuthor() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    
    if (title.isEmpty && author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.atLeastOneSearchField)),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final book = await bookProvider.searchBooks(
        title: title.isNotEmpty ? title : null,
        author: author.isNotEmpty ? author : null,
      );
      
      if (mounted) {
        if (book != null) {
          // Navigate to BookEditScreen with found book
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookEditScreen(
                initialBook: book,
              ),
            ),
          );
          
          // Refresh libraries if book was added
          if (result == true && mounted) {
            final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
            await libraryProvider.fetchLibraries();
            Navigator.pop(context, true);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bookNotFound)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.searchError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _navigateToCreateManually() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookEditScreen(),
      ),
    );
    
    // Refresh libraries if book was added
    if (result == true && mounted) {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      await libraryProvider.fetchLibraries();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchByIsbn),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search by ISBN section
              Text(
                l10n.searchByIsbn,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.deltaTeal,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _isbnController,
                decoration: InputDecoration(
                  labelText: l10n.isbn,
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
                enabled: !_isSearching,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchByIsbn(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchByIsbn,
                  icon: _isSearching
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? l10n.searching : l10n.search),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldLeaf,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              // OR separator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.borderMedium,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.or,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.borderMedium,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Title and Author search section
              Text(
                l10n.searchByTitleAuthor,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.deltaTeal,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '${l10n.title} (${l10n.optional.toLowerCase()})',
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
                enabled: !_isSearching,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: '${l10n.author} (${l10n.optional.toLowerCase()})',
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
                enabled: !_isSearching,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchByTitleAuthor(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchByTitleAuthor,
                  icon: _isSearching
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? l10n.searching : l10n.search),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldLeaf,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Create Manually button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSearching ? null : _navigateToCreateManually,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createManually),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepSeaBlue,
                    side: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
