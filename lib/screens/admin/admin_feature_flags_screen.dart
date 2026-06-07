import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../../providers/feature_flag_provider.dart';
import '../../theme/app_colors.dart';

// Backend follow-up required:
// The admin feature flags screen requires the following endpoints that do not
// yet exist on the backend:
//   GET  /admin/feature_flags          — list all flags with global state
//   POST /admin/feature_flags/:name/enable    — enable a flag globally
//   POST /admin/feature_flags/:name/disable   — disable a flag globally
//   POST /admin/feature_flags/:name/enable_for_user  — enable for actor (body: { email: "..." })
//
// Until these endpoints are implemented, this screen reads the current user's
// flag state from FeatureFlagProvider (read-only) and shows the Flipper UI
// note. Toggle and per-user actions are marked TODO.

class AdminFeatureFlagsScreen extends StatelessWidget {
  const AdminFeatureFlagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminFeatureFlags),
        backgroundColor: AppColors.deepSeaBlue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<FeatureFlagProvider>(
        builder: (context, flagProvider, _) {
          final flags = flagProvider.isLoading
              ? <String, bool>{}
              : Map<String, bool>.from(flagProvider.allFlags);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackendNote(context, l10n),
                const SizedBox(height: 20),
                if (flagProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (flags.isEmpty)
                  Text(
                    l10n.noFeatureFlags,
                    style: const TextStyle(color: AppColors.textSecondary),
                  )
                else ...[
                  Text(
                    l10n.adminFeatureFlags,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deltaTeal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...flags.entries.map((e) => _FlagCard(
                        flagName: e.key,
                        isEnabled: e.value,
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackendNote(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.featureFlagsAdminNote,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.featureFlagsAdminDescription,
            style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  final String flagName;
  final bool isEnabled;

  const _FlagCard({required this.flagName, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    flagName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.deltaTeal,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEnabled ? l10n.enableFlag : l10n.disableFlag,
                    style: TextStyle(
                      color: isEnabled ? Colors.green : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // TODO: implement once POST /admin/feature_flags/:name/enable|disable exists
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null, // TODO: call enable/disable endpoint
                    icon: Icon(
                      isEnabled ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
                      size: 18,
                    ),
                    label: Text(isEnabled ? l10n.disableFlag : l10n.enableFlag),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEnableForUserSheet(context, l10n),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: Text(l10n.enableForUser),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEnableForUserSheet(BuildContext context, AppLocalizations l10n) {
    // TODO: implement once POST /admin/feature_flags/:name/enable_for_user exists
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EnableForUserSheet(flagName: flagName),
    );
  }
}

class _EnableForUserSheet extends StatefulWidget {
  final String flagName;

  const _EnableForUserSheet({required this.flagName});

  @override
  State<_EnableForUserSheet> createState() => _EnableForUserSheetState();
}

class _EnableForUserSheetState extends State<_EnableForUserSheet> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.enableForUser}: ${widget.flagName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.deltaTeal,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.email,
              hintText: 'user@example.com',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // TODO: implement once POST /admin/feature_flags/:name/enable_for_user exists
              onPressed: null,
              child: Text(l10n.enableForUser),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.featureFlagsAdminNote,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
