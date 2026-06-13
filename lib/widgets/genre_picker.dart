import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../models/genre.dart';
import '../providers/genre_provider.dart';
import '../theme/app_colors.dart';

class GenrePicker extends StatefulWidget {
  final List<String> initialSlugs;
  final void Function(List<String> slugs) onDone;

  const GenrePicker({
    super.key,
    required this.initialSlugs,
    required this.onDone,
  });

  @override
  State<GenrePicker> createState() => _GenrePickerState();
}

class _GenrePickerState extends State<GenrePicker> {
  late List<String> _selected;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initialSlugs);
    _searchController.addListener(() {
      context.read<GenreProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    context.read<GenreProvider>().setSearchQuery('');
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String slug) {
    setState(() {
      if (_selected.contains(slug)) {
        _selected.remove(slug);
      } else {
        _selected.add(slug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRo = Localizations.localeOf(context).languageCode == 'ro';

    return Consumer<GenreProvider>(
      builder: (context, genreProvider, _) {
        final filtered = genreProvider.filteredGenres;
        final groups = _searchController.text.isEmpty
            ? genreProvider.groupedGenres
            : null;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.genrePickerTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deltaTeal,
                          ),
                    ),
                  ),
                ),

                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.genreSearchPlaceholder,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context.read<GenreProvider>().setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),

                // Selected chips
                if (_selected.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _selected.map((slug) {
                          final matched = genreProvider.slugsToGenres([slug]);
                          final label = matched.isNotEmpty
                              ? (isRo ? matched.first.nameRo : matched.first.nameEn)
                              : slug;
                          return Chip(
                            label: Text(label, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => _toggle(slug),
                            backgroundColor: AppColors.deepSeaBlue.withValues(alpha: 0.12),
                            side: const BorderSide(color: AppColors.deepSeaBlue, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            labelStyle: const TextStyle(color: AppColors.deepSeaBlue),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],

                const Divider(height: 8),

                // Genre list
                Expanded(
                  child: genreProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                l10n.genreNoneSelected,
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : groups != null
                              ? _buildGroupedList(groups, isRo, scrollController)
                              : _buildFlatList(filtered, isRo, scrollController),
                ),

                const Divider(height: 1),

                // Footer
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    8 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() => _selected.clear()),
                        child: Text(l10n.genreClear),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          widget.onDone(List<String>.from(_selected));
                          Navigator.pop(context);
                        },
                        child: Text(l10n.genreDone),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGroupedList(
    Map<String, List<Genre>> groups,
    bool isRo,
    ScrollController scrollController,
  ) {
    final keys = groups.keys.toList()..sort();
    return ListView.builder(
      controller: scrollController,
      itemCount: keys.fold<int>(0, (sum, k) => sum + 1 + groups[k]!.length),
      itemBuilder: (context, index) {
        int offset = 0;
        for (final key in keys) {
          if (index == offset) {
            return _buildHeader(key);
          }
          offset++;
          final list = groups[key]!;
          if (index < offset + list.length) {
            return _buildTile(list[index - offset], isRo);
          }
          offset += list.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFlatList(
    List<Genre> genres,
    bool isRo,
    ScrollController scrollController,
  ) {
    return ListView.builder(
      controller: scrollController,
      itemCount: genres.length,
      itemBuilder: (_, i) => _buildTile(genres[i], isRo),
    );
  }

  Widget _buildHeader(String letter) {
    return Container(
      color: AppColors.riverMist,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Text(
        letter,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTile(Genre genre, bool isRo) {
    final label = isRo ? genre.nameRo : genre.nameEn;
    final selected = _selected.contains(genre.slug);
    return CheckboxListTile(
      value: selected,
      onChanged: (_) => _toggle(genre.slug),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      activeColor: AppColors.deepSeaBlue,
      dense: true,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}

Future<List<String>?> showGenrePicker(
  BuildContext context, {
  required List<String> initialSlugs,
}) async {
  List<String>? result;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => GenrePicker(
      initialSlugs: initialSlugs,
      onDone: (slugs) => result = slugs,
    ),
  );
  return result;
}
