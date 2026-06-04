import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../models/wishlist_item.dart';
import '../models/library.dart';
import '../providers/wishlist_provider.dart';
import '../providers/library_provider.dart';
import '../theme/app_colors.dart';
import '../utils/image_utils.dart';

class WishlistDetailScreen extends StatefulWidget {
  final WishlistItem item;
  final bool readOnly;

  const WishlistDetailScreen({super.key, required this.item, this.readOnly = false});

  @override
  State<WishlistDetailScreen> createState() => _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends State<WishlistDetailScreen> {
  late TextEditingController _noteController;
  late String _priority;
  bool _isSaving = false;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.item.note ?? '');
    _priority = widget.item.priority;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _priorityLabel(BuildContext context, String p) {
    final l10n = AppLocalizations.of(context)!;
    switch (p) {
      case 'high': return l10n.priorityHigh;
      case 'low': return l10n.priorityLow;
      default: return l10n.priorityMedium;
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return Colors.red.shade400;
      case 'low': return Colors.green.shade400;
      default: return Colors.orange.shade400;
    }
  }

  Future<void> _saveChanges() async {
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    setState(() => _isSaving = true);
    final ok = await wishlistProvider.updateItem(
      widget.item.id,
      note: _noteController.text.trim(),
      priority: _priority,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) Navigator.pop(context, true);
    }
  }

  Future<void> _moveToLibrary() async {
    final l10n = AppLocalizations.of(context)!;
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final libraries = libraryProvider.libraries;

    if (libraries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noLibraries)));
      return;
    }

    Library? chosen;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _LibraryPickerSheet(libraries: libraries, onSelected: (lib) { chosen = lib; Navigator.pop(ctx); }),
    );

    if (chosen == null || !mounted) return;

    setState(() => _isMoving = true);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    final ok = await wishlistProvider.moveToLibrary(widget.item.id, chosen!.id);
    if (mounted) {
      setState(() => _isMoving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.movedToLibrary)));
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final book = widget.item.book;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (!widget.readOnly)
            IconButton(
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
              onPressed: _isSaving ? null : _saveChanges,
              tooltip: l10n.save,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.coverUrl != null
                      ? Image.network(
                          proxiedCoverUrl(book.coverUrl)!,
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _coverPlaceholder(book),
                        )
                      : _coverPlaceholder(book),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(book.author, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      if (book.seriesName != null) ...[
                        const SizedBox(height: 4),
                        Text(book.seriesName!, style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontStyle: FontStyle.italic)),
                      ],
                      if (book.genre != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.riverMist, borderRadius: BorderRadius.circular(8)),
                          child: Text(book.genre!, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                      if (book.totalPages != null) ...[
                        const SizedBox(height: 4),
                        Text('${book.totalPages} pages', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Priority selector
            Text(l10n.priority, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final selected = _priority == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_priorityLabel(context, p)),
                    selected: selected,
                    onSelected: widget.readOnly ? null : (_) => setState(() => _priority = p),
                    selectedColor: _priorityColor(p).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selected ? _priorityColor(p) : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(color: selected ? _priorityColor(p) : AppColors.borderLight),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Note field
            Text(l10n.wishlistNote, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              readOnly: widget.readOnly,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: widget.readOnly ? null : l10n.wishlistNoteHint,
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2)),
              ),
            ),

            if (!widget.readOnly) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isMoving ? null : _moveToLibrary,
                  icon: _isMoving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.library_add),
                  label: Text(l10n.iGotIt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deltaTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder(WishlistBook book) => Container(
        width: 80,
        height: 120,
        decoration: BoxDecoration(color: AppColors.riverMist, borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(book.title.isNotEmpty ? book.title[0].toUpperCase() : '?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
      );
}

class _LibraryPickerSheet extends StatelessWidget {
  final List<Library> libraries;
  final void Function(Library) onSelected;

  const _LibraryPickerSheet({required this.libraries, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Text(l10n.selectLibrary, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...libraries.map((lib) => ListTile(
                leading: Icon(lib.shared ? Icons.people : Icons.library_books, color: AppColors.deepSeaBlue),
                title: Text(lib.name),
                onTap: () => onSelected(lib),
              )),
        ],
      ),
    );
  }
}
