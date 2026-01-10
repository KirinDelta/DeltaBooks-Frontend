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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Could add book details navigation here
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.book,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 30,
                              ),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.book,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 30,
                            ),
                          ),
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
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.isbn}: ${book.isbn}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (book.totalPages > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.page} ${book.totalPages}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );
  }

}
