import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../models/book_stats.dart';
import '../models/library_stats.dart';
import '../models/library.dart';
import '../theme/app_colors.dart';

enum StatsScope { allUsers, justMe }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final PageController _pageController = PageController();
  int? _selectedYear;
  StatsScope _currentScope = StatsScope.allUsers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadStats();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    final selectedLibrary = libraryProvider.selectedLibrary;

    if (selectedLibrary != null) {
      // Fetch library stats for the selected library
      final isShared = libraryProvider.isSharedLibrary(selectedLibrary);
      String? scope;
      // Only use scope for shared libraries when "Just Me" is selected
      if (isShared && _currentScope == StatsScope.justMe) {
        scope = 'personal';
      }
      await libraryProvider.fetchLibraryStats(
        selectedLibrary.id.toString(),
        year: _selectedYear,
        scope: scope,
      );
    } else {
      // Fetch personal stats when no library is selected
    await libraryProvider.fetchPersonalStats(year: _selectedYear);
    }
  }

  void _onYearChanged(int? year) {
        setState(() {
      _selectedYear = year;
        });
    _loadStats();
  }

  void _onScopeChanged(StatsScope scope) {
    setState(() {
      _currentScope = scope;
        });
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, _) {
        final selectedLibrary = libraryProvider.selectedLibrary;
        final isShared = selectedLibrary != null && libraryProvider.isSharedLibrary(selectedLibrary);
        
        final isLoading = selectedLibrary != null
            ? libraryProvider.isStatsLoading
            : libraryProvider.isPersonalStatsLoading;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 56.0,
            title: isShared 
                ? const Text('Library Statistics') 
                : const Text('Personal Statistics'),
          ),
          body: isLoading
              ? RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            )
              : _buildBody(context, libraryProvider, selectedLibrary, isShared, l10n),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    LibraryProvider libraryProvider,
    Library? selectedLibrary,
    bool isShared,
    AppLocalizations l10n,
  ) {
    // Determine which stats to show
    final libraryStats = selectedLibrary != null ? libraryProvider.libraryStats : null;
    final personalStats = selectedLibrary == null ? libraryProvider.personalStats : null;
    
    if ((selectedLibrary != null && libraryStats == null) ||
        (selectedLibrary == null && personalStats == null)) {
      return RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Text(
                l10n.statsError,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
      );
    }

    // Get available years from the stats
    final availableYears = libraryStats != null
        ? libraryStats.availableYears
        : (personalStats?.availableYears ?? []);

    // Check for empty state
    final totalBooks = libraryStats != null
        ? libraryStats.totalBooks
        : (personalStats?.totalBooks ?? 0);

    if (totalBooks == 0) {
      return RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Text(
                'No data yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scope selector (TabBar/ToggleButtons) - only for shared libraries
            if (isShared) ...[
              _buildScopeSelector(context),
              const SizedBox(height: 24),
            ],

            // Year selector
            _buildYearSelector(context, availableYears),
            const SizedBox(height: 24),

            // Swipeable stat cards
            if (libraryStats != null)
              _buildSwipeableStatCardsForLibrary(context, libraryStats)
            else if (personalStats != null)
              _buildSwipeableStatCardsForPersonal(context, personalStats),
            const SizedBox(height: 24),

            // Authors chart
            if (libraryStats != null)
              _buildAuthorsChartForLibrary(context, libraryStats)
            else if (personalStats != null)
              _buildAuthorsChartForPersonal(context, personalStats),
            const SizedBox(height: 24),

            // Reading timeline chart
            if (libraryStats != null)
              _buildReadingTimelineChartForLibrary(context, libraryStats)
            else if (personalStats != null)
              _buildReadingTimelineChartForPersonal(context, personalStats),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.riverMist.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _buildScopeButton(
              context,
              'All Users',
              StatsScope.allUsers,
            ),
          ),
          Expanded(
            child: _buildScopeButton(
              context,
              'Just Me',
              StatsScope.justMe,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeButton(BuildContext context, String label, StatsScope scope) {
    final isSelected = _currentScope == scope;
    return GestureDetector(
      onTap: () => _onScopeChanged(scope),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepSeaBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelector(BuildContext context, List<int> availableYears) {
    // If no years available, show current year
    final years = availableYears.isEmpty
        ? [DateTime.now().year]
        : availableYears..sort((a, b) => b.compareTo(a));

    // Set default year if not selected
    if (_selectedYear == null && years.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedYear = years.first;
        });
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.riverMist.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelected = _selectedYear == year;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                year.toString(),
                style: TextStyle(
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onYearChanged(year);
                }
              },
              selectedColor: AppColors.deepSeaBlue,
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: isSelected
                    ? AppColors.deepSeaBlue
                    : AppColors.borderLight,
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeableStatCardsForLibrary(
      BuildContext context, LibraryStats stats) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 3,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return _buildLibraryStatCard1(context, stats);
                case 1:
                  return _buildLibraryStatCard2(context, stats);
                case 2:
                  return _buildLibraryStatCard3(context, stats);
                default:
                  return const SizedBox();
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _pageController,
          count: 3,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            spacing: 8,
            dotColor: AppColors.riverMist,
            activeDotColor: AppColors.deepSeaBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeableStatCardsForPersonal(
      BuildContext context, BookStats stats) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 3,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return _buildPersonalStatCard1(context, stats);
                case 1:
                  return _buildPersonalStatCard2(context, stats);
                case 2:
                  return _buildPersonalStatCard3(context, stats);
                default:
                  return const SizedBox();
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _pageController,
          count: 3,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            spacing: 8,
            dotColor: AppColors.riverMist,
            activeDotColor: AppColors.deepSeaBlue,
          ),
        ),
      ],
    );
  }

  // Library Card 1: Total Books
  Widget _buildLibraryStatCard1(BuildContext context, LibraryStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riverMist, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 48, color: AppColors.deepSeaBlue),
          const SizedBox(height: 16),
          Text(
            '${stats.totalBooks}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.deltaTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Books',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  // Library Card 2: Total Pages
  Widget _buildLibraryStatCard2(BuildContext context, LibraryStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riverMist, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 48, color: AppColors.deepSeaBlue),
          const SizedBox(height: 16),
          Text(
            '${stats.totalPages}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.deltaTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Pages',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  // Library Card 3: Reading Progress
  Widget _buildLibraryStatCard3(BuildContext context, LibraryStats stats) {
    final readPercentage = stats.readPercentage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riverMist, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 48, color: AppColors.deepSeaBlue),
          const SizedBox(height: 16),
          Text(
            'Reading Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${readPercentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.deepSeaBlue,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.readCount} of ${stats.readCount + stats.unreadCount} books read',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  // Personal Card 1: Read Books
  Widget _buildPersonalStatCard1(BuildContext context, BookStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riverMist, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 48, color: AppColors.deepSeaBlue),
          const SizedBox(height: 16),
          Text(
            '${stats.totalBooks}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.deltaTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Books Read',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  // Personal Card 2: Total Pages
  Widget _buildPersonalStatCard2(BuildContext context, BookStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riverMist, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 48, color: AppColors.deepSeaBlue),
          const SizedBox(height: 16),
          Text(
            '${stats.totalPages}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.deltaTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Pages',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  // Personal Card 3: Collection Value
  Widget _buildPersonalStatCard3(BuildContext context, BookStats stats) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'RON ',
      decimalDigits: 2,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riverMist, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_money, size: 48, color: AppColors.goldLeaf),
          const SizedBox(height: 16),
          Text(
            'Total Value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(stats.totalValue),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.deltaTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorsChartForLibrary(
      BuildContext context, LibraryStats stats) {
    // Convert Map to sorted list and take top 10
    final authorsList = stats.authorsChart.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topAuthors = authorsList.take(10).toList();

    if (topAuthors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.riverMist, width: 1),
        ),
        child: Text(
          'No authors data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Find max for scaling
    final maxBooks = topAuthors
        .map((entry) => entry.value)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riverMist, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Authors',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.deltaTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: topAuthors.length * 40.0,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxBooks.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.deepSeaBlue,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < topAuthors.length) {
                          final authorName = topAuthors[index].key;
                          final displayName = authorName.length > 10
                              ? '${authorName.substring(0, 10)}...'
                              : authorName;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 50,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: topAuthors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final authorEntry = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: authorEntry.value.toDouble(),
                        color: AppColors.deepSeaBlue,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorsChartForPersonal(
      BuildContext context, BookStats stats) {
    // Convert Map to sorted list and take top 10
    final authorsList = stats.authorsChart.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topAuthors = authorsList.take(10).toList();

    if (topAuthors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.riverMist, width: 1),
        ),
        child: Text(
          'No authors data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
      );
    }

    // Find max for scaling
    final maxBooks = topAuthors
        .map((entry) => entry.value)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riverMist, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
            'Top Authors',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.deltaTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: topAuthors.length * 40.0,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxBooks.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.deepSeaBlue,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < topAuthors.length) {
                          final authorName = topAuthors[index].key;
                          final displayName = authorName.length > 10
                              ? '${authorName.substring(0, 10)}...'
                              : authorName;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 50,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: topAuthors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final authorEntry = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: authorEntry.value.toDouble(),
                color: AppColors.deepSeaBlue,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildReadingTimelineChartForLibrary(
      BuildContext context, LibraryStats stats) {
    final timeline = stats.readingTimeline;

    if (timeline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.riverMist, width: 1),
        ),
        child: Text(
          'No reading timeline data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Find max for scaling
    final maxBooks = timeline
        .map((entry) => entry.books)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riverMist, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Timeline',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.deltaTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxBooks.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.deepSeaBlue,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final year = timeline[groupIndex].year;
                      final books = timeline[groupIndex].books;
                      return BarTooltipItem(
                        '$year\n$books book${books == 1 ? '' : 's'}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < timeline.length) {
                          final year = timeline[index].year;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              year.toString(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: timeline.asMap().entries.map((entry) {
                  final index = entry.key;
                  final timelineEntry = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: timelineEntry.books.toDouble(),
                        color: AppColors.deepSeaBlue,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTimelineChartForPersonal(
      BuildContext context, BookStats stats) {
    final timeline = stats.readingTimeline;

    if (timeline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.riverMist, width: 1),
        ),
        child: Text(
          'No reading timeline data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Find max for scaling
    final maxBooks = timeline
        .map((entry) => entry.books)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riverMist, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Timeline',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.deltaTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxBooks.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.deepSeaBlue,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final year = timeline[groupIndex].year;
                      final books = timeline[groupIndex].books;
                      return BarTooltipItem(
                        '$year\n$books book${books == 1 ? '' : 's'}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < timeline.length) {
                          final year = timeline[index].year;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              year.toString(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: timeline.asMap().entries.map((entry) {
                  final index = entry.key;
                  final timelineEntry = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: timelineEntry.books.toDouble(),
                        color: AppColors.deepSeaBlue,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}