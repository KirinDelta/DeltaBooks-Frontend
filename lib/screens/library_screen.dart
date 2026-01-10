import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../models/book.dart';

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
    // Listen to library changes to refresh books
    final libraryProvider = Provider.of<LibraryProvider>(context);
    
    // Refresh books when library changes
    final selectedLibrary = libraryProvider.selectedLibrary;
    final currentLibraryId = selectedLibrary?.id;
    if (currentLibraryId != _lastLibraryId && currentLibraryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchBooks();
      });
    }
    
    // Show books from selected library - books are included in the library object
    final isShared = selectedLibrary != null && libraryProvider.isSharedLibrary(selectedLibrary);
    final books = selectedLibrary?.books ?? [];

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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: book.coverUrl != null
                ? Image.network(
                    book.coverUrl!,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.book),
                  )
                : const Icon(Icons.book, size: 50),
            title: Text(book.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.author),
                const SizedBox(height: 4),
                Text('${l10n.isbn}: ${book.isbn}'),
                if (book.totalPages > 0)
                  Text('${l10n.page} ${book.totalPages}'),
              ],
            ),
          ),
        );
      },
      ),
    );
  }

}
