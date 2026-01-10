import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/book_provider.dart';
import '../services/api_service.dart';
import 'dart:convert';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/v1/dashboard');
      if (response.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null) {
      return Center(child: Text(l10n.statsError));
    }

    final combined = (_stats!['combined'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final user = (_stats!['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final partner = (_stats!['partner'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatCard(
            context,
            l10n.pagesReadThisMonth,
            '${user['pages_read'] ?? 0}',
            Icons.book,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            context,
            l10n.totalLibraryValue,
            '${(combined['money_spent'] ?? 0.0).toStringAsFixed(2)} RON',
            Icons.attach_money,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            context,
            l10n.totalBooks,
            '${combined['total_books'] ?? 0}',
            Icons.library_books,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            context,
            l10n.totalPagesRead,
            '${combined['pages_read'] ?? 0}',
            Icons.menu_book,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFF1A365D)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF1A365D),
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
