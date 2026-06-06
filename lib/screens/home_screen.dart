import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../models/book_stats.dart';
import '../models/library.dart';
import '../models/user_book.dart';
import '../providers/book_provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/library_provider.dart';
import '../theme/app_images.dart';
import '../theme/app_colors.dart';
import '../utils/image_utils.dart';
import 'book_detail_screen.dart';
import 'invitations_screen.dart';
import 'libraries_screen.dart';
import 'library_screen.dart';
import 'manual_entry_screen.dart';
import 'scanner_screen.dart';
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
      Provider.of<LibraryProvider>(context, listen: false).fetchPersonalStats();
      Provider.of<BookProvider>(context, listen: false).fetchMyBooks();
      Provider.of<InvitationProvider>(context, listen: false).fetchInvitations();
    });
  }

  void _showAddBookSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.goldLeaf.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_scanner,
                        color: AppColors.goldLeaf),
                  ),
                  title: Text(l10n.scanBarcodeTip,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(l10n.scanBarcode,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScannerScreen(addMode: true),
                      ),
                    );
                    if (result == true && mounted) {
                      libraryProvider.fetchLibraries();
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.deepSeaBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: AppColors.deepSeaBlue),
                  ),
                  title: Text(l10n.addManually,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(l10n.searchByIsbn,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManualEntryScreen(addMode: true),
                      ),
                    );
                    if (result == true && mounted) {
                      libraryProvider.fetchLibraries();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
                                  .withValues(alpha: 0.1)
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
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '(${l10n.shared})',
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
                                      Text(
                                        '(${l10n.shared})',
                                        style: const TextStyle(
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
    final isHomeTab = _currentTabIndex == 0;

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
                      tooltip: l10n.shareLibrary,
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
                  tooltip: l10n.manageLibraries,
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
            : isHomeTab
                ? [
                    Consumer<InvitationProvider>(
                      builder: (context, invProvider, _) {
                        final count = invProvider.pendingReceivedCount;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Colors.white),
                              tooltip: l10n.invitations,
                              onPressed: () async {
                                final ip = Provider.of<InvitationProvider>(
                                    context,
                                    listen: false);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const InvitationsScreen()),
                                );
                                if (mounted) ip.fetchInvitations();
                              },
                            ),
                            if (count > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
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
          const _HomeDashboard(),
          LibraryScreen(key: _libraryScreenKey),
          const WishlistScreen(),
          const YouScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookSheet(context),
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
            _buildNavItem(Icons.home_outlined, Icons.home, l10n.home, 0),
            _buildNavItem(
                Icons.library_books_outlined, Icons.library_books, l10n.shelves, 1),
            const SizedBox(width: 48), // FAB notch gap
            _buildNavItem(
                Icons.bookmark_outline, Icons.bookmark, l10n.wishlist, 2),
            _buildNavItem(Icons.person_outline, Icons.person, l10n.you, 3),
          ],
        ),
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<LibraryProvider, BookProvider>(
      builder: (context, libraryProvider, bookProvider, _) {
        final stats = libraryProvider.personalStats;
        final isStatsLoading = libraryProvider.isPersonalStatsLoading;
        final readingBooks = bookProvider.myBooks
            .where((ub) => ub.status == BookStatus.reading)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isStatsLoading && stats == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _buildStatCards(context, l10n, stats),
              const SizedBox(height: 28),
              Text(
                l10n.currentlyReading,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.deltaTeal,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (bookProvider.isLoading && readingBooks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (readingBooks.isEmpty)
                _buildEmptyReading(context, l10n)
              else
                ...readingBooks.map((ub) => _buildReadingCard(context, ub)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards(
      BuildContext context, AppLocalizations l10n, BookStats? stats) {
    final currencyFormat =
        NumberFormat.currency(symbol: 'RON ', decimalDigits: 0);

    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.library_books,
            color: AppColors.deepSeaBlue,
            value: stats != null ? '${stats.totalBooks}' : '—',
            label: l10n.totalBooks,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.menu_book,
            color: AppColors.deltaTeal,
            value: stats != null ? '${stats.totalPages}' : '—',
            label: l10n.totalPagesRead,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.payments_outlined,
            color: AppColors.goldLeaf,
            value: stats != null ? currencyFormat.format(stats.totalValue) : '—',
            label: l10n.moneySpent,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.deltaTeal,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReading(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.riverMist.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_stories_outlined,
              size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            l10n.noBooksInProgress,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(BuildContext context, UserBook ub) {
    final book = ub.book;
    final hasProgress = ub.currentPage != null &&
        ub.currentPage! > 0 &&
        book.totalPages > 0;
    final progress =
        hasProgress ? (ub.currentPage! / book.totalPages).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(
            book: book,
            libraryId: book.libraryId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: book.coverUrl != null
                  ? Image.network(
                      proxiedCoverUrl(book.coverUrl)!,
                      width: 48,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(),
                    )
                  : _coverPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.deltaTeal,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasProgress) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.riverMist,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.goldLeaf),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ub.currentPage} / ${book.totalPages}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 48,
      height: 68,
      decoration: const BoxDecoration(
        color: AppColors.riverMist,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: const Icon(Icons.book, color: AppColors.textTertiary, size: 22),
    );
  }
}

