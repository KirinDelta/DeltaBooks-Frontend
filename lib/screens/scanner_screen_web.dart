import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../theme/app_colors.dart';
import 'manual_entry_screen.dart';

// Stub used on web — mobile_scanner is not supported in browsers.
// Re-exports ScannerWebStub as ScannerMobile so scanner_screen.dart
// conditional import resolves to the same symbol on both platforms.
class ScannerMobile extends StatelessWidget {
  const ScannerMobile({super.key});

  @override
  Widget build(BuildContext context) => const ScannerWebStub();
}

class ScannerWebStub extends StatelessWidget {
  const ScannerWebStub({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 72,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.scannerNotAvailableOnWeb,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.scannerWebFallbackMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FloatingActionButton.extended(
                  heroTag: 'add_manual_fab_web',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManualEntryScreen(),
                      ),
                    );

                    if (result == true && context.mounted) {
                      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
                      await libraryProvider.fetchLibraries();
                    }
                  },
                  icon: const Icon(Icons.keyboard),
                  label: Text(l10n.addManually),
                  backgroundColor: AppColors.goldLeaf,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
