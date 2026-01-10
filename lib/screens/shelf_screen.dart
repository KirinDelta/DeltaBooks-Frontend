import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../models/user_book.dart';

class ShelfScreen extends StatelessWidget {
  final bool isMyShelf;

  const ShelfScreen({super.key, required this.isMyShelf});

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return FutureBuilder(
      future: isMyShelf ? bookProvider.fetchMyBooks() : bookProvider.fetchPartnerBooks(),
      builder: (context, snapshot) {
        final books = isMyShelf ? bookProvider.myBooks : bookProvider.partnerBooks;

        if (bookProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (books.isEmpty) {
          return Center(
            child: Text(
              isMyShelf ? 'Raftul tău este gol' : 'Raftul partenerului este gol',
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
                    Text(_getStatusText(userBook.status)),
                    if (userBook.currentPage != null)
                      Text('Pagina ${userBook.currentPage}/${userBook.book.totalPages}'),
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
      },
    );
  }

  String _getStatusText(BookStatus status) {
    switch (status) {
      case BookStatus.reading:
        return 'În citire';
      case BookStatus.finished:
        return 'Terminat';
      default:
        return 'Necitit';
    }
  }
}
