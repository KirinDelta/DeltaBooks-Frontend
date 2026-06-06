import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import 'library_statistics_screen.dart';
import 'profile_screen.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  void _navigateToStats(
      BuildContext context, LibraryProvider libraryProvider) {
    final selected = libraryProvider.selectedLibrary;
    if (selected == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectLibraryFirst)),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryStatisticsScreen(libraryId: selected.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<AuthProvider, LibraryProvider>(
      builder: (context, authProvider, libraryProvider, _) {
        final user = authProvider.user;

        final firstName = user?.firstName;
        final lastName = user?.lastName;
        final email = user?.email ?? '';

        String? displayName;
        if (firstName != null && firstName.isNotEmpty) {
          displayName = lastName != null && lastName.isNotEmpty
              ? '$firstName $lastName'
              : firstName;
        } else if (lastName != null && lastName.isNotEmpty) {
          displayName = lastName;
        }

        return ListView(
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  UserAvatar(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    size: 72,
                  ),
                  const SizedBox(height: 16),
                  if (displayName != null) ...[
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deltaTeal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.borderLight),

            // Statistics
            ListTile(
              leading: const Icon(Icons.bar_chart, color: AppColors.deltaTeal),
              title: Text(
                l10n.statistics,
                style: const TextStyle(color: AppColors.deltaTeal),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
              onTap: () => _navigateToStats(context, libraryProvider),
            ),

            // Edit Profile — label flagged for Phase 6 localisation
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.deltaTeal),
              title: const Text(
                'Edit Profile',
                style: TextStyle(color: AppColors.deltaTeal),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),

            const Divider(height: 1, color: AppColors.borderLight),

            // Logout
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.logout,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => authProvider.logout(),
            ),
          ],
        );
      },
    );
  }
}
