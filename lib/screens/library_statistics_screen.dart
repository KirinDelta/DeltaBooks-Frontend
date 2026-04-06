import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../providers/library_provider.dart';
import '../models/library_stats.dart';
import '../models/library.dart';
import '../theme/app_colors.dart';

enum StatsScope { allUsers, justMe }

class LibraryStatisticsScreen extends StatefulWidget {
  final int libraryId;

  const LibraryStatisticsScreen({
    super.key,
    required this.libraryId,
  });

  @override
  State<LibraryStatisticsScreen> createState() =>
      _LibraryStatisticsScreenState();
}

class _LibraryStatisticsScreenState extends State<LibraryStatisticsScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int? _selectedYear;
  StatsScope _currentScope = StatsScope.allUsers;
  final Map<String, bool> _expandedSections = {
    'authors': false,
    'progress': false,
    'timeline': false,
  };

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
    final library = libraryProvider.getLibraryById(widget.libraryId);
    final isShared = library != null && libraryProvider.isSharedLibrary(library);
    
    String? scope;
    // Only use scope for shared libraries when "Just Me" is selected
    if (isShared && _currentScope == StatsScope.justMe) {
      scope = 'personal';
    }
    
    await libraryProvider.fetchLibraryStats(
      widget.libraryId.toString(),
      year: _selectedYear,
      scope: scope,
    );
  }

  void _onYearChanged(int? year) {
    if (year != _selectedYear) {
      setState(() {
        _selectedYear = year;
      });
      _loadStats();
    }
  }

  void _onScopeChanged(StatsScope scope) {
    setState(() {
      _currentScope = scope;
    });
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, _) {
          final library = libraryProvider.getLibraryById(widget.libraryId);
          final isShared = library != null && libraryProvider.isSharedLibrary(library);
          
          if (libraryProvider.isStatsLoading) {
            return RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            );
          }

          final stats = libraryProvider.libraryStats;
          if (stats == null) {
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

          // Check for empty state
          if (stats.totalBooks == 0) {
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
                  // Scope selector (All Users / Just Me) - only for shared libraries
                  if (isShared) ...[
                    _buildScopeSelector(context),
                    const SizedBox(height: 16),
                  ],

                  // Swipeable stat cards
                  _buildSwipeableStatCards(context, stats, _currentScope),
                  const SizedBox(height: 24),

                  // Expandable sections
                  _buildExpandableSections(context, stats),
                ],
              ),
            ),
          );
        },
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
    final years = [...availableYears]..sort((a, b) => b.compareTo(a));

    if (_selectedYear == null && years.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onYearChanged(years.first);
      });
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: years.map((year) {
          final isSelected = _selectedYear == year;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(year.toString()),
              selected: isSelected,
              onSelected: (_) => _onYearChanged(year),
              selectedColor: AppColors.deepSeaBlue,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSwipeableStatCards(BuildContext context, LibraryStats stats, StatsScope scope) {
    final isJustMe = scope == StatsScope.justMe;
    final cardCount = isJustMe ? 2 : 3;
    
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: cardCount,
            itemBuilder: (context, index) {
              if (isJustMe) {
                // Just Me: Card 1 = Read Books, Card 2 = Reading Progress
                switch (index) {
                  case 0:
                    return _buildStatCard1(context, stats, isJustMe: true);
                  case 1:
                    return _buildStatCard3(context, stats);
                  default:
                    return const SizedBox();
                }
              } else {
                // All Users: Card 1 = Total Books, Card 2 = Value, Card 3 = Reading Progress
                switch (index) {
                  case 0:
                    return _buildStatCard1(context, stats, isJustMe: false);
                  case 1:
                    return _buildStatCard2(context, stats);
                  case 2:
                    return _buildStatCard3(context, stats);
                  default:
                    return const SizedBox();
                }
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _pageController,
          count: cardCount,
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

  // Card 1: Books/Pages (or Read Books for Just Me)
  Widget _buildStatCard1(BuildContext context, LibraryStats stats, {required bool isJustMe}) {
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
          if (isJustMe) ...[
            // Just Me: Show read books, pages read, and authors
            Text(
              '${stats.readCount} Books Read',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.deltaTeal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.totalPages} Pages',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'by ${stats.totalAuthors} Authors',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ] else ...[
            // All Users: Show total books, pages, authors
            Text(
              '${stats.totalBooks} Books',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.deltaTeal,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.totalPages} Pages',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'by ${stats.totalAuthors} Authors',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  // Card 2: Financial Value
  Widget _buildStatCard2(BuildContext context, LibraryStats stats) {
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

  // Card 3: Reading Progress
  Widget _buildStatCard3(BuildContext context, LibraryStats stats) {
    final readPercentage = stats.totalBooks > 0
        ? (stats.readCount / stats.totalBooks) * 100
        : 0.0;

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
            '${stats.readCount} books Read out of ${stats.totalBooks}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSections(BuildContext context, LibraryStats stats) {
    return Column(
      children: [
        // Author Distribution
        _buildExpandableAuthorSection(context, stats),
        const SizedBox(height: 16),

        // Read Progress Chart
        _buildExpandableProgressSection(context, stats),
        const SizedBox(height: 16),

        // Time-series Chart
        _buildExpandableTimelineSection(context, stats),
      ],
    );
  }

  Widget _buildExpandableAuthorSection(
      BuildContext context, LibraryStats stats) {
    final isExpanded = _expandedSections['authors'] ?? false;

    return Container(
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
      child: ExpansionTile(
        title: Text(
          'Author Distribution',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.deltaTeal,
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          '${stats.authorsChart.length} authors',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        leading: Icon(Icons.person, color: AppColors.deepSeaBlue),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedSections['authors'] = expanded;
          });
        },
        children: [
          if (stats.authorsChart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildTopAuthorsChart(context, stats),
            )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No authors data available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableProgressSection(
      BuildContext context, LibraryStats stats) {
    final isExpanded = _expandedSections['progress'] ?? false;

    return Container(
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
      child: ExpansionTile(
        title: Text(
          'Read Progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.deltaTeal,
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          '${stats.readCount} read, ${stats.unreadCount} unread',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        leading: Icon(Icons.pie_chart, color: AppColors.deepSeaBlue),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedSections['progress'] = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildReadProgressChart(context, stats),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableTimelineSection(
      BuildContext context, LibraryStats stats) {
    final isExpanded = _expandedSections['timeline'] ?? false;

    return Container(
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
      child: ExpansionTile(
        title: Text(
          'Reading Timeline',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.deltaTeal,
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          'Timeline view',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        leading: Icon(Icons.timeline, color: AppColors.deepSeaBlue),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedSections['timeline'] = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTimelineChart(context, stats),
          ),
        ],
      ),
    );
  }

  Widget _buildReadProgressChart(
      BuildContext context, LibraryStats stats) {
    final total = stats.readCount + stats.unreadCount;
    if (total == 0) {
      return Center(
        child: Text(
          'No read progress data',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    final readPercentage = stats.readPercentage;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: stats.readCount.toDouble(),
                      color: AppColors.deepSeaBlue,
                      title: '',
                      radius: 65,
                    ),
                    PieChartSectionData(
                      value: stats.unreadCount.toDouble(),
                      color: AppColors.riverMist,
                      title: '',
                      radius: 65,
                    ),
                  ],
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${readPercentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.deepSeaBlue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Read',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              context,
              'Read',
              AppColors.deepSeaBlue,
              stats.readCount,
            ),
            const SizedBox(width: 24),
            _buildLegendItem(
              context,
              'Unread',
              AppColors.riverMist,
              stats.unreadCount,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineChart(BuildContext context, LibraryStats stats) {
    final timeline = stats.readingTimeline;

    if (timeline.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No timeline data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Find max for scaling
    final maxBooks = timeline
        .map((entry) => entry.books)
        .reduce((a, b) => a > b ? a : b);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 300,
      child: FadeIn(
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
    );
  }

  Widget _buildTopAuthorsChart(BuildContext context, LibraryStats stats) {
    // Convert Map to sorted list and take top 10
    final authorsList = stats.authorsChart.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topAuthors = authorsList.take(10).toList();

    // Find max for scaling
    final maxBooks = topAuthors.isEmpty
        ? 1
        : topAuthors.map((entry) => entry.value).reduce((a, b) => a > b ? a : b);

    return Column(
      children: topAuthors.asMap().entries.map((entry) {
        final authorEntry = entry.value;
        final authorName = authorEntry.key;
        final bookCount = authorEntry.value;
        final barWidth = MediaQuery.of(context).size.width - 120;
        final barLength = (bookCount / maxBooks) * barWidth;

        final displayName = authorName.length > 25
            ? '${authorName.substring(0, 25)}...'
            : authorName;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  displayName,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.riverMist.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      width: barLength,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.deepSeaBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 30,
                child: Text(
                  bookCount.toString(),
                  style: TextStyle(
                    color: AppColors.deltaTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(
      BuildContext context, String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

// Simple fade-in animation widget
class FadeIn extends StatefulWidget {
  final Widget child;

  const FadeIn({super.key, required this.child});

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
