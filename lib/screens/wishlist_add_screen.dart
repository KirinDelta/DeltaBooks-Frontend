import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../theme/app_colors.dart';
import 'search_results_screen.dart';

class WishlistAddScreen extends StatefulWidget {
  final String? initialIsbn;

  const WishlistAddScreen({super.key, this.initialIsbn});

  @override
  State<WishlistAddScreen> createState() => _WishlistAddScreenState();
}

class _WishlistAddScreenState extends State<WishlistAddScreen> {
  final _isbnController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIsbn != null) {
      _isbnController.text = widget.initialIsbn!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchByIsbn());
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.enterIsbnError)));
      return;
    }
    setState(() => _isSearching = true);
    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final books = await bookProvider.searchBooks(isbn: isbn);
      if (!mounted) return;
      if (books.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.bookNotFound)));
      } else {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(
              books: books,
              searchQuery: isbn,
              wishlistMode: true,
            ),
          ),
        );
        if (result == true && mounted) Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.searchError)));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _searchByTitleAuthor() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    if (title.isEmpty && author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.atLeastOneSearchField)));
      return;
    }
    setState(() => _isSearching = true);
    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final books = await bookProvider.searchBooks(
        title: title.isNotEmpty ? title : null,
        author: author.isNotEmpty ? author : null,
      );
      if (!mounted) return;
      if (books.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.bookNotFound)));
      } else {
        final query = [title, author].where((s) => s.isNotEmpty).join(' / ');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(
              books: books,
              searchQuery: query,
              wishlistMode: true,
            ),
          ),
        );
        if (result == true && mounted) Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.searchError)));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.riverMist,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  Widget _searchButton(String label, VoidCallback? onPressed) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: _isSearching
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.search),
          label: Text(_isSearching ? AppLocalizations.of(context)!.searching : label),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.goldLeaf,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addToWishlist)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.searchByIsbn, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.deltaTeal)),
              const SizedBox(height: 16),
              TextField(
                controller: _isbnController,
                decoration: _fieldDecoration(l10n.isbn, hint: l10n.enterIsbn),
                keyboardType: TextInputType.number,
                enabled: !_isSearching,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchByIsbn(),
              ),
              const SizedBox(height: 16),
              _searchButton(l10n.search, _isSearching ? null : _searchByIsbn),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l10n.or, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  ),
                  const Expanded(child: Divider()),
                ]),
              ),
              Text(l10n.searchByTitleAuthor, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.deltaTeal)),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: _fieldDecoration('${l10n.title} (${l10n.optional.toLowerCase()})'),
                enabled: !_isSearching,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: _fieldDecoration('${l10n.author} (${l10n.optional.toLowerCase()})'),
                enabled: !_isSearching,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchByTitleAuthor(),
              ),
              const SizedBox(height: 16),
              _searchButton(l10n.search, _isSearching ? null : _searchByTitleAuthor),
            ],
          ),
        ),
      ),
    );
  }
}
