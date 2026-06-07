import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../../models/admin_user.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_colors.dart';
import 'admin_feature_flags_screen.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String? _selectedStatus;

  static const _statusOptions = [null, 'active', 'suspended'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AdminProvider>().fetchUsers(
              email: query.isNotEmpty ? query : null,
              accountStatus: _selectedStatus,
            );
      }
    });
  }

  void _onStatusChanged(String? status) {
    setState(() => _selectedStatus = status);
    context.read<AdminProvider>().fetchUsers(
          email: _searchController.text.isNotEmpty ? _searchController.text : null,
          accountStatus: status,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<AdminProvider>();
      if (!provider.isLoading && provider.hasNextPage) {
        provider.fetchUsers(
          email: _searchController.text.isNotEmpty ? _searchController.text : null,
          accountStatus: _selectedStatus,
          page: provider.currentPage + 1,
        );
      }
    }
  }

  Future<void> _onRefresh() {
    return context.read<AdminProvider>().fetchUsers(
          email: _searchController.text.isNotEmpty ? _searchController.text : null,
          accountStatus: _selectedStatus,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminUsers),
        backgroundColor: AppColors.deepSeaBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.toggle_on_outlined, color: Colors.white),
            tooltip: l10n.adminFeatureFlags,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminFeatureFlagsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(context, l10n),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, provider, _) {
                if (provider.error != null) {
                  return _buildError(context, provider, l10n);
                }
                if (provider.isLoading && provider.users.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.users.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noUsers,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: provider.users.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.users.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _AdminUserCard(user: provider.users[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.searchUsers,
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                l10n.filterByStatus,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              ..._statusOptions.map((status) {
                final isSelected = _selectedStatus == status;
                final label = status == null
                    ? l10n.allStatuses
                    : status == 'active'
                        ? l10n.activeStatus
                        : l10n.suspended;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => _onStatusChanged(status),
                    selectedColor: AppColors.deepSeaBlue.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.deepSeaBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.deepSeaBlue : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(
      BuildContext context, AdminProvider provider, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.error ?? '',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              provider.clearError();
              _onRefresh();
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  final AdminUser user;

  const _AdminUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminUserDetailScreen(userId: user.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: user.isSuspended
                    ? Colors.red.withValues(alpha: 0.15)
                    : AppColors.deepSeaBlue.withValues(alpha: 0.12),
                child: Text(
                  user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: user.isSuspended ? Colors.red : AppColors.deepSeaBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.deltaTeal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isAdmin) ...[
                          const SizedBox(width: 6),
                          _StatusBadge(
                            label: 'Admin',
                            color: AppColors.goldLeaf,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusBadge(
                          label: user.isSuspended ? l10n.suspended : l10n.activeStatus,
                          color: user.isSuspended ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user.librariesCount} ${l10n.libraries.toLowerCase()}',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user.userBooksCount} books',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
}
