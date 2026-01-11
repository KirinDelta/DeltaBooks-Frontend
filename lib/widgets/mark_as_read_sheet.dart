import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../providers/library_provider.dart';
import '../models/book.dart';
import '../theme/app_colors.dart';

class MarkAsReadSheet extends StatefulWidget {
  final Book book;
  final int libraryId;

  const MarkAsReadSheet({
    super.key,
    required this.book,
    required this.libraryId,
  });

  @override
  State<MarkAsReadSheet> createState() => _MarkAsReadSheetState();
}

class _MarkAsReadSheetState extends State<MarkAsReadSheet> {
  int? _selectedRating;
  final TextEditingController _commentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.deepSeaBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.deltaTeal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveReading() async {
    final l10n = AppLocalizations.of(context)!;
    
    setState(() => _isSaving = true);

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final success = await bookProvider.markBookAsRead(
        bookId: widget.book.id!,
        libraryId: widget.libraryId,
        rating: _selectedRating,
        comment: _commentController.text.trim().isNotEmpty 
            ? _commentController.text.trim() 
            : null,
        readAt: _selectedDate,
        pagesRead: widget.book.totalPages > 0 ? widget.book.totalPages : null,
      );

      if (mounted) {
        if (success) {
          // Refresh libraries to get updated data
          final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
          await libraryProvider.fetchLibraries();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.readingSaved)),
          );
          
          // Return true to indicate refresh is needed
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.readingError)),
          );
          Navigator.pop(context, false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.readingError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.riverMist,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Text(
            l10n.markAsRead,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.deltaTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.book.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Star Rating
          Text(
            l10n.selectRating,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.deltaTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = _selectedRating == rating ? null : rating;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    _selectedRating != null && rating <= _selectedRating!
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColors.goldLeaf,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          
          // Comment field
          Text(
            l10n.comment,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.deltaTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.enterComment,
              filled: true,
              fillColor: Colors.white,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(color: AppColors.deltaTeal),
          ),
          const SizedBox(height: 24),
          
          // Date picker
          Text(
            l10n.readDate,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.deltaTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(
                      color: AppColors.deltaTeal,
                      fontSize: 16,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.deepSeaBlue,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Save button
          ElevatedButton(
            onPressed: _isSaving ? null : _saveReading,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldLeaf,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.saveReading,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
