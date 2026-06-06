import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/library_provider.dart';
import '../models/library.dart';
import '../theme/app_images.dart';
import '../theme/app_colors.dart';
import 'libraries_screen.dart';
import 'library_screen.dart';
import 'share_library_screen.dart';
import 'wishlist_screen.dart';
import 'you_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0=Home, 1=Shelves, 2=Wishlist, 3=You
  int _currentTabIndex = 0;
  final GlobalKey<LibraryScreenState> _libraryScreenKey =
      GlobalKey<LibraryScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LibraryProvider>(context, listen: false).fetchLibraries();
      Provider.of<InvitationProvider>(context, listen: false).fetchInvitations();
    });
  }

  void _showLibrarySelector(
    BuildContext context,
    LibraryProvider libraryProvider,
    List<Library> allLibraries,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final selectedLibrary = libraryProvider.selectedLibrary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 8,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                l10n.selectLibrary,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allLibraries.length + 1,
                  itemBuilder: (context, index) {
                    // Last item: create new library
                    if (index == allLibraries.length) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          l10n.createLibrary,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LibrariesScreen()),
                          );
                          if (mounted) {
                            await libraryProvider.fetchLibraries();
                          }
                        },
                      );
                    }

                    final library = allLibraries[index];
                    final isShared = libraryProvider.isSharedLibrary(library);
                    final isSelected = selectedLibrary?.id == library.id;

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isShared ? Icons.people : Icons.library_books,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              library.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isShared) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '(Shared)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Theme.of(context).colorScheme.tertiary,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            )
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      onTap: () async {
                        Navigator.pop(context);
                        libraryProvider.selectLibrary(library);
                        final bookProvider =
                            Provider.of<BookProvider>(context, listen: false);
                        if (isShared) {
                          await bookProvider.fetchPartnerBooks(
                              libraryId: library.id);
                        } else {
                          await bookProvider.fetchMyBooks(
                              libraryId: library.id);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildLibrarySelectorBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PreferredSize(
      preferredSize: const Size.fromHeight(51.0),
      child: Container(
        color: AppColors.deepSeaBlue,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1.0, color: Colors.white10),
            Consumer<LibraryProvider>(
              builder: (context, libraryProvider, _) {
                if (libraryProvider.isLoading) {
                  return const SizedBox(
                    height: 50.0,
                    child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  );
                }

                final allLibraries = libraryProvider.allLibraries;
                final selectedLibrary = libraryProvider.selectedLibrary;
                final isSelectedShared = selectedLibrary != null &&
                    libraryProvider.isSharedLibrary(selectedLibrary);

                return Container(
                  height: 50.0,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.centerLeft,
                  child: allLibraries.isEmpty
                      ? InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LibrariesScreen()),
                            );
                            if (mounted) {
                              await libraryProvider.fetchLibraries();
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_circle_outline,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                l10n.createLibraryFirst,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : InkWell(
                          onTap: () => _showLibrarySelector(
                              context, libraryProvider, allLibraries),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        selectedLibrary?.name ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelectedShared) ...[
                                      const SizedBox(width: 6),
                                      const Text(
                                        '(Shared)',
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.white70,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final state =
                                          _libraryScreenKey.currentState;
                                      if (state != null) {
                                        return ValueListenableBuilder<int>(
                                          valueListenable:
                                              state.filteredBookCountNotifier,
                                          builder: (context, count, _) {
                                            return Text(
                                              '$count',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      return Text(
                                        '${selectedLibrary?.books.length ?? 0}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down,
                                      color: Colors.white, size: 24),
                                ],
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData outlinedIcon, IconData filledIcon, String label, int index) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTabIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : outlinedIcon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isShelvesTab = _currentTabIndex == 1;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56.0,
        title: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                AppImages.logo,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        actions: isShelvesTab
            ? [
                // Share icon — only when the selected library is owned by the user
                Consumer<LibraryProvider>(
                  builder: (context, libraryProvider, _) {
                    final selected = libraryProvider.selectedLibrary;
                    if (selected == null || !selected.isOwner) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: const Icon(Icons.person_add_outlined,
                          color: Colors.white),
                      tooltip: 'Share library',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ShareLibraryScreen(selectedLibrary: selected),
                        ),
                      ),
                    );
                  },
                ),
                // Gear icon — always visible on Shelves tab
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: Colors.white),
                  tooltip: 'Manage libraries',
                  onPressed: () async {
                    final libraryProvider = Provider.of<LibraryProvider>(
                        context,
                        listen: false);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LibrariesScreen()),
                    );
                    if (mounted) {
                      libraryProvider.fetchLibraries();
                    }
                  },
                ),
              ]
            : null,
        bottom: isShelvesTab ? _buildLibrarySelectorBar(context) : null,
        backgroundColor: AppColors.deepSeaBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          const _HomePlaceholder(),
          LibraryScreen(key: _libraryScreenKey),
          const WishlistScreen(),
          const YouScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon')),
          );
        },
        backgroundColor: AppColors.goldLeaf,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
            _buildNavItem(
                Icons.library_books_outlined, Icons.library_books, 'Shelves', 1),
            const SizedBox(width: 48), // FAB notch gap
            _buildNavItem(
                Icons.bookmark_outline, Icons.bookmark, l10n.wishlist, 2),
            _buildNavItem(Icons.person_outline, Icons.person, 'You', 3),
          ],
        ),
      ),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home', style: TextStyle(fontSize: 24)),
    );
  }
}

