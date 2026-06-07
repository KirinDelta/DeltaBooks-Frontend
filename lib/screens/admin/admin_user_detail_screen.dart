import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../../models/admin_user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final int userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  AdminUserDetail? _detail;
  bool _isLoading = true;
  String? _error;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final detail =
        await context.read<AdminProvider>().fetchUserDetail(widget.userId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _isLoading = detail == null
            ? false
            : false; // error is on the provider if detail is null
        _error = detail == null ? context.read<AdminProvider>().error : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _suspend(AppLocalizations l10n) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: l10n.suspendUser,
      message: l10n.confirmSuspend,
      confirmLabel: l10n.suspend,
      confirmColor: Colors.red,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isActing = true);
    final ok = await context.read<AdminProvider>().suspendUser(widget.userId);
    if (mounted) {
      setState(() => _isActing = false);
      if (ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.suspendSuccess)));
        await _load();
      } else {
        final err = context.read<AdminProvider>().error ?? l10n.errorSuspending;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        context.read<AdminProvider>().clearError();
      }
    }
  }

  Future<void> _unsuspend(AppLocalizations l10n) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: l10n.unsuspendUser,
      message: l10n.confirmUnsuspend,
      confirmLabel: l10n.unsuspend,
      confirmColor: AppColors.deepSeaBlue,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isActing = true);
    final ok = await context.read<AdminProvider>().unsuspendUser(widget.userId);
    if (mounted) {
      setState(() => _isActing = false);
      if (ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.unsuspendSuccess)));
        await _load();
      } else {
        final err = context.read<AdminProvider>().error ?? l10n.errorUnsuspending;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        context.read<AdminProvider>().clearError();
      }
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userDetail),
        backgroundColor: AppColors.deepSeaBlue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ?? l10n.userDetail,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final detail = _detail!;
    final currentUser = context.read<AuthProvider>().user;
    final isSelf = currentUser?.id == detail.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(context, detail, l10n),
          const SizedBox(height: 20),
          _buildStats(context, detail, l10n),
          const SizedBox(height: 20),
          _buildSuspendAction(context, detail, l10n, isSelf),
          const SizedBox(height: 24),
          _buildMemberships(context, detail, l10n),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, AdminUserDetail detail, AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.deepSeaBlue.withValues(alpha: 0.12),
                  child: Text(
                    detail.email.isNotEmpty ? detail.email[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.deepSeaBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deltaTeal,
                        ),
                      ),
                      if (detail.username.isNotEmpty)
                        Text(
                          '@${detail.username}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (detail.isAdmin)
                  _badge('Admin', AppColors.goldLeaf),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),
            _infoRow(Icons.email_outlined, l10n.email, detail.email),
            if (detail.createdAt != null)
              _infoRow(
                Icons.calendar_today_outlined,
                l10n.joinedOn,
                _formatDate(detail.createdAt!),
              ),
            _infoRow(
              detail.isSuspended ? Icons.block : Icons.check_circle_outline,
              'Status',
              detail.isSuspended ? l10n.suspended : l10n.activeStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(
      BuildContext context, AdminUserDetail detail, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.library_books,
            color: AppColors.deepSeaBlue,
            value: '${detail.librariesCount}',
            label: l10n.libraries,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.menu_book,
            color: AppColors.deltaTeal,
            value: '${detail.userBooksCount}',
            label: 'Books',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.bookmark_outline,
            color: AppColors.goldLeaf,
            value: '${detail.wishlistItemsCount}',
            label: l10n.wishlist,
          ),
        ),
      ],
    );
  }

  Widget _buildSuspendAction(
    BuildContext context,
    AdminUserDetail detail,
    AppLocalizations l10n,
    bool isSelf,
  ) {
    if (detail.isAdmin) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.cannotSuspendAdmin,
                style: const TextStyle(color: Colors.amber, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (isSelf) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.cannotSuspendSelf,
                style: const TextStyle(color: Colors.amber, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: _isActing
          ? const Center(child: CircularProgressIndicator())
          : detail.isSuspended
              ? ElevatedButton.icon(
                  onPressed: () => _unsuspend(l10n),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.unsuspend),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () => _suspend(l10n),
                  icon: const Icon(Icons.block, color: Colors.red),
                  label: Text(
                    l10n.suspend,
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
    );
  }

  Widget _buildMemberships(
      BuildContext context, AdminUserDetail detail, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.libraryMemberships,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.deltaTeal,
          ),
        ),
        const SizedBox(height: 12),
        if (detail.libraryMemberships.isEmpty)
          Text(
            l10n.noLibraries,
            style: const TextStyle(color: AppColors.textSecondary),
          )
        else
          ...detail.libraryMemberships.map((m) => _membershipCard(context, m, l10n)),
      ],
    );
  }

  Widget _membershipCard(
      BuildContext context, AdminLibraryMembership m, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            m.isOwner ? Icons.library_books : Icons.people_outline,
            color: AppColors.deltaTeal,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(
                    color: AppColors.deltaTeal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (m.joinedAt != null)
                  Text(
                    _formatDate(m.joinedAt!),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          _badge(
            m.isOwner ? l10n.ownerBadge : l10n.memberBadge,
            m.isOwner ? AppColors.goldLeaf : AppColors.deltaTeal,
          ),
        ],
      ),
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
        color: Colors.white,
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.deltaTeal,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.deltaTeal,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
