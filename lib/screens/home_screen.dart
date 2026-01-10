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
      backgroundColor: const Color(0xFF1A365D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
                      leading: Icon(
                        isShared ? Icons.people : Icons.library_books,
                        color: isSelected ? Colors.amber : Colors.white70,
                      ),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              library.name,
                              style: TextStyle(
                                color: isSelected ? Colors.amber : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isShared) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(Shared)',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.amber.shade300 : Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.amber, size: 24)
                          : null,
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
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
        actions: [
          Consumer<LibraryProvider>(
            builder: (context, libraryProvider, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.library_books),
                onSelected: (value) async {
                  if (value == 'manage') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LibrariesScreen(),
                      ),
                    );
                    if (mounted) {
                      await libraryProvider.fetchLibraries();
                    }
                  } else if (value == 'invite') {
                    final selectedLibrary = libraryProvider.selectedLibrary;
                    if (selectedLibrary != null) {
                      await Navigator.push(
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
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'manage',
                    child: Row(
                      children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 8),
                        Text(l10n.myLibraries),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'invite',
                    child: Row(
                      children: [
                        const Icon(Icons.person_add),
                        const SizedBox(width: 8),
                        Text(l10n.shareLibrary),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Consumer<InvitationProvider>(
            builder: (context, invitationProvider, _) {
              final pendingCount = invitationProvider.pendingReceivedCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline),
                    tooltip: l10n.invitations,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InvitationsScreen(),
                        ),
                      );
                    },
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
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: l10n.language,
            onPressed: () {
              localeProvider.toggleLocale();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
            },
          ),
        ],
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
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          LibraryScreen(),
          ScannerScreen(),
          StatsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books),
            label: l10n.myLibrary,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.qr_code_scanner),
            label: l10n.scan,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: l10n.statistics,
          ),
        ],
      ),
    );
  }
}
