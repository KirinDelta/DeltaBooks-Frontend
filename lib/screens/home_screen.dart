import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/invitation_provider.dart';
import 'scanner_screen.dart';
import 'stats_screen.dart';
import 'library_screen.dart';
import 'share_library_screen.dart';
import 'invitations_screen.dart';

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
    // Fetch invitations when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvitationProvider>(context, listen: false).fetchInvitations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
        actions: [
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
            icon: const Icon(Icons.person_add),
            tooltip: l10n.shareLibrary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ShareLibraryScreen(),
                ),
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
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          LibraryScreen(isMyLibrary: true),
          LibraryScreen(isMyLibrary: false),
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
            icon: const Icon(Icons.people),
            label: l10n.partnerLibrary,
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
