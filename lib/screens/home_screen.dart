import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/library_provider.dart';
import '../models/library.dart';
import '../theme/app_images.dart';
import '../theme/app_colors.dart';
import 'scanner_screen.dart';
import 'library_screen.dart';
import 'library_statistics_screen.dart';
import 'share_library_screen.dart';
import 'invitations_screen.dart';
import 'libraries_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<LibraryScreenState> _libraryScreenKey = GlobalKey<LibraryScreenState>();

  @override
  void initState() {
    super.initState();
    // Fetch libraries and invitations when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
      libraryProvider.fetchLibraries(); // This now fetches both own and shared libraries
      invitationProvider.fetchInvitations();
    });
  }
  
  void _showSortBottomSheet() {
    _libraryScreenKey.currentState?.showSortBottomSheetFromParent();
  }

  void _showLibrarySelector(BuildContext context, LibraryProvider libraryProvider, List<Library> allLibraries) {
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
                  itemCount: allLibraries.length,
                  itemBuilder: (context, index) {
                    final library = allLibraries[index];
                    final isShared = libraryProvider.isSharedLibrary(library);
                    final isSelected = selectedLibrary?.id == library.id;
                    
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isShared) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '(Shared)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.tertiary,
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () async {
                        Navigator.pop(context);
                        libraryProvider.selectLibrary(library);
                        final bookProvider = Provider.of<BookProvider>(context, listen: false);
                        if (isShared) {
                          await bookProvider.fetchPartnerBooks(libraryId: library.id);
                        } else {
                          await bookProvider.fetchMyBooks(libraryId: library.id);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56.0,
        title: Builder(
          builder: (builderContext) => Padding(
            padding: const EdgeInsets.only(left: 0, right: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menu Icon (Left)
                Transform.translate(
                  offset: const Offset(-8, 0),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(builderContext).openDrawer(),
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
                  ),
                ),
                // Logo (Right)
                Padding(
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
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(51.0),
          child: Container(
            color: AppColors.deepSeaBlue,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Divider between rows
                Container(
                  height: 1.0,
                  color: Colors.white10,
                ),
                // Library Dropdown Row
                Consumer<LibraryProvider>(
                  builder: (context, libraryProvider, _) {
                    if (libraryProvider.isLoading) {
                      return const SizedBox(
                        height: 50.0,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      );
                    }
                    
                    final allLibraries = libraryProvider.allLibraries;
                    final selectedLibrary = libraryProvider.selectedLibrary;
                    final isSelectedShared = selectedLibrary != null && libraryProvider.isSharedLibrary(selectedLibrary);
                    
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
                                    builder: (_) => const LibrariesScreen(),
                                  ),
                                );
                                if (mounted) {
                                  await libraryProvider.fetchLibraries();
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.createLibraryFirst,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : InkWell(
                              onTap: () => _showLibrarySelector(context, libraryProvider, allLibraries),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Library name and (Shared) indicator (left-aligned)
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
                                  // Book counter and dropdown arrow (right-aligned)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final libraryScreenState = _libraryScreenKey.currentState;
                                          if (libraryScreenState != null) {
                                            return ValueListenableBuilder<int>(
                                              valueListenable: libraryScreenState.filteredBookCountNotifier,
                                              builder: (context, filteredCount, child) {
                                                return Text(
                                                  '$filteredCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                  ),
                                                );
                                              },
                                            );
                                          } else {
                                            // Fallback to total count if library screen state is not available yet
                                            return Text(
                                              '${selectedLibrary?.books.length ?? 0}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
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
        ),
        backgroundColor: AppColors.deepSeaBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LibraryScreen(key: _libraryScreenKey),
          const ScannerScreen(),
          _buildStatisticsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.library_books, l10n.myLibrary, 0),
              _buildNavItem(Icons.qr_code_scanner, l10n.scan, 1),
              _buildNavItem(Icons.bar_chart, l10n.statistics, 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, _) {
        final selectedLibrary = libraryProvider.selectedLibrary;

        if (selectedLibrary == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a library to view statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a library from the dropdown above',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return LibraryStatisticsScreen(
          libraryId: selectedLibrary.id,
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer3<AuthProvider, LibraryProvider, InvitationProvider>(
      builder: (context, authProvider, libraryProvider, invitationProvider, _) {
        final pendingCount = invitationProvider.pendingReceivedCount;
        final user = authProvider.user;
        final userEmail = user?.email ?? '';
        
        // Construct user name from firstName and lastName
        String? userName;
        final firstName = user?.firstName;
        final lastName = user?.lastName;
        if (firstName != null && firstName.isNotEmpty) {
          if (lastName != null && lastName.isNotEmpty) {
            userName = '$firstName $lastName';
          } else {
            userName = firstName;
          }
        } else if (lastName != null && lastName.isNotEmpty) {
          userName = lastName;
        }
        
        // Determine if we should show name as primary (and email as secondary)
        final hasName = userName != null && userName.isNotEmpty;
        
        return Drawer(
          child: SafeArea(
            child: Column(
              children: [
                // Drawer Header
                Container(
                  padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0, bottom: 0.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular logo container
                      Container(
                        height: 70.0,
                        padding: const EdgeInsets.all(10.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          AppImages.logo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      // User Name (Bold)
                      if (hasName && userName != null)
                        Text(
                          userName!,
                          style: const TextStyle(
                            color: AppColors.deltaTeal,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Drawer menu items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.settings,
                          color: AppColors.deltaTeal,
                        ),
                        title: Text(
                          l10n.myLibraries,
                          style: const TextStyle(color: AppColors.deltaTeal),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LibrariesScreen(),
                            ),
                          );
                          if (mounted) {
                            await libraryProvider.fetchLibraries();
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.person_add,
                          color: AppColors.deltaTeal,
                        ),
                        title: Text(
                          l10n.shareLibrary,
                          style: const TextStyle(color: AppColors.deltaTeal),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          final selectedLibrary = libraryProvider.selectedLibrary;
                          if (selectedLibrary != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShareLibraryScreen(selectedLibrary: selectedLibrary),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.selectLibraryFirst)),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: Stack(
                          children: [
                            const Icon(
                              Icons.mail_outline,
                              color: AppColors.deltaTeal,
                            ),
                            if (pendingCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Text(
                              l10n.invitations,
                              style: const TextStyle(color: AppColors.deltaTeal),
                            ),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InvitationsScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: AppColors.deltaTeal,
                        ),
                        title: Text(
                          l10n.profile,
                          style: const TextStyle(color: AppColors.deltaTeal),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(color: AppColors.riverMist),
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          l10n.logout,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          await authProvider.logout();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
