import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/library_provider.dart';
import '../models/library.dart';
import 'scanner_screen.dart';
import 'stats_screen.dart';
import 'library_screen.dart';
import 'share_library_screen.dart';
import 'invitations_screen.dart';
import 'libraries_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.appTitle),
            Consumer<LibraryProvider>(
              builder: (context, libraryProvider, _) {
                if (libraryProvider.isLoading || libraryProvider.allLibraries.isEmpty) {
                  return const SizedBox.shrink();
                }
                final selectedLibrary = libraryProvider.selectedLibrary;
                if (selectedLibrary == null) return const SizedBox.shrink();
                final isShared = libraryProvider.isSharedLibrary(selectedLibrary);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isShared) ...[
                      const Icon(Icons.people, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        selectedLibrary.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          fontStyle: isShared ? FontStyle.italic : FontStyle.normal,
                          color: isShared ? Colors.amber : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isShared) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(Shared)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber.shade300,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer<LibraryProvider>(
            builder: (context, libraryProvider, _) {
              if (libraryProvider.isLoading) {
                return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()));
              }
              
              final allLibraries = libraryProvider.allLibraries;
              final selectedLibrary = libraryProvider.selectedLibrary;
              final isSelectedShared = selectedLibrary != null && libraryProvider.isSharedLibrary(selectedLibrary);
              
              if (allLibraries.isEmpty) {
                return Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.createLibraryFirst,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return InkWell(
                onTap: () => _showLibrarySelector(context, libraryProvider, allLibraries),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.library_books, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
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
                              const SizedBox(width: 8),
                              Text(
                                '(Shared)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      drawer: _buildDrawer(context, localeProvider),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          LibraryScreen(),
          ScannerScreen(),
          StatsScreen(),
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
              _buildMoreMenu(context, localeProvider),
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

  Widget _buildMoreMenu(BuildContext context, LocaleProvider localeProvider) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<InvitationProvider>(
      builder: (context, invitationProvider, _) {
        final pendingCount = invitationProvider.pendingReceivedCount;
        return Expanded(
          child: Builder(
            builder: (builderContext) => InkWell(
              onTap: () => Scaffold.of(builderContext).openDrawer(),
              child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.more_vert,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      if (pendingCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.more,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, LocaleProvider localeProvider) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer3<AuthProvider, LibraryProvider, InvitationProvider>(
      builder: (context, authProvider, libraryProvider, invitationProvider, _) {
        final pendingCount = invitationProvider.pendingReceivedCount;
        final userEmail = authProvider.user?.email ?? '';
        return Drawer(
          child: SafeArea(
            child: Column(
              children: [
                // Drawer header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userEmail.isNotEmpty ? userEmail : l10n.more,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
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
                        leading: Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        title: Text(l10n.myLibraries),
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
                        leading: Icon(
                          Icons.person_add,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        title: Text(l10n.shareLibrary),
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
                            Icon(
                              Icons.mail_outline,
                              color: Theme.of(context).colorScheme.onSurface,
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
                            Text(l10n.invitations),
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
                        leading: Icon(
                          Icons.language,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        title: Text(l10n.language),
                        onTap: () {
                          Navigator.pop(context);
                          localeProvider.toggleLocale();
                        },
                      ),
                      const Divider(),
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
