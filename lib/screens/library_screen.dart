import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../models/user_book.dart';

class LibraryScreen extends StatefulWidget {
  final bool isMyLibrary;

  const LibraryScreen({super.key, required this.isMyLibrary});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBooks();
    });
  }

  void _fetchBooks() {
    if (!_hasFetched && mounted) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      if (widget.isMyLibrary) {
        bookProvider.fetchMyBooks();
      } else {
        bookProvider.fetchPartnerBooks();
      }
      _hasFetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Only listen to changes, don't rebuild unnecessarily
    final bookProvider = Provider.of<BookProvider>(context);
    final books = widget.isMyLibrary ? bookProvider.myBooks : bookProvider.partnerBooks;

    if (bookProvider.isLoading && !_hasFetched) {
      return const Center(child: CircularProgressIndicator());
    }

    if (books.isEmpty && !bookProvider.isLoading) {
      return Center(
        child: Text(
          widget.isMyLibrary ? l10n.emptyLibrary : l10n.emptyPartnerLibrary,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final userBook = books[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: userBook.book.coverUrl != null
                ? Image.network(
                    userBook.book.coverUrl!,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.book),
                  )
                : const Icon(Icons.book, size: 50),
            title: Text(userBook.book.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userBook.book.author),
                const SizedBox(height: 4),
                Text(_getStatusText(userBook.status, l10n)),
                if (userBook.currentPage != null)
                  Text('${l10n.page} ${userBook.currentPage}/${userBook.book.totalPages}'),
              ],
            ),
            trailing: userBook.rating != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < userBook.rating! ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  String _getStatusText(BookStatus status, AppLocalizations l10n) {
    switch (status) {
      case BookStatus.reading:
        return l10n.reading;
      case BookStatus.finished:
        return l10n.finished;
      default:
        return l10n.unread;
    }
  }
}
