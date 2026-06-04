import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../models/wishlist_item.dart';
import '../providers/wishlist_provider.dart';
import '../theme/app_colors.dart';
import '../utils/image_utils.dart';
import 'wishlist_add_screen.dart';
import 'wishlist_detail_screen.dart';
import 'scanner_screen.dart';

enum _SortMode { date, priority, title }

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  _SortMode _sortMode = _SortMode.date;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
    });
  }

  List<WishlistItem> _sorted(List<WishlistItem> items) {
    final copy = List<WishlistItem>.from(items);
    switch (_sortMode) {
      case _SortMode.priority:
        copy.sort((a, b) => b.priorityOrder.compareTo(a.priorityOrder));
      case _SortMode.title:
        copy.sort((a, b) => a.book.title.compareTo(b.book.title));
      case _SortMode.date:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return copy;
  }

  void _showSortSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ..._SortMode.values.map((mode) {
              final label = switch (mode) {
                _SortMode.date => l10n.sortByDate,
                _SortMode.priority => l10n.sortByPriority,
                _SortMode.title => l10n.sortByTitle,
              };
              return ListTile(
                title: Text(label),
                trailing: _sortMode == mode ? Icon(Icons.check, color: AppColors.deepSeaBlue) : null,
                onTap: () { setState(() => _sortMode = mode); Navigator.pop(context); },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.deepSeaBlue),
              title: Text(l10n.scanBarcode),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen(wishlistMode: true)));
                if (result == true && mounted) {
                  Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.keyboard, color: AppColors.deepSeaBlue),
              title: Text(l10n.addManually),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistAddScreen()));
                if (result == true && mounted) {
                  Provider.of<WishlistProvider>(context, listen: false).fetchWishlist();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(WishlistItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.removeFromWishlist),
        content: Text(item.book.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remove, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await Provider.of<WishlistProvider>(context, listen: false).removeFromWishlist(item.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.removedFromWishlist)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wishlist),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: _showSortSheet, tooltip: l10n.sort),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        heroTag: 'wishlist_fab',
        child: const Icon(Icons.add),
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border, size: 72, color: AppColors.textTertiary),
                    const SizedBox(height: 16),
                    Text(l10n.wishlistEmpty, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }

          final sorted = _sorted(provider.items);
          return RefreshIndicator(
            onRefresh: provider.fetchWishlist,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: sorted.length,
              itemBuilder: (context, index) => _WishlistTile(
                item: sorted[index],
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WishlistDetailScreen(item: sorted[index])),
                  );
                  if (result == true) provider.fetchWishlist();
                },
                onDelete: () => _confirmDelete(sorted[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WishlistTile({required this.item, required this.onTap, required this.onDelete});

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return Colors.red.shade400;
      case 'low': return Colors.green.shade400;
      default: return Colors.orange.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = item.book;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade100,
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // deletion is handled in _confirmDelete
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: book.coverUrl != null
                      ? Image.network(
                          proxiedCoverUrl(book.coverUrl)!,
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(book),
                        )
                      : _placeholder(book),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: _priorityColor(item.priority), shape: BoxShape.circle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(book.author, style: TextStyle(color: AppColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis),
                      if (book.seriesName != null) ...[
                        const SizedBox(height: 2),
                        Text(book.seriesName!, style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis),
                      ],
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.note!, style: TextStyle(color: AppColors.textTertiary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(WishlistBook book) => Container(
        width: 50,
        height: 75,
        decoration: BoxDecoration(color: AppColors.riverMist, borderRadius: BorderRadius.circular(6)),
        child: Center(child: Text(book.title.isNotEmpty ? book.title[0].toUpperCase() : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
      );
}
