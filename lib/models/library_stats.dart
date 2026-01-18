import 'book_stats.dart';

class LibraryStats {
  final int totalBooks;
  final int totalPages;
  final int totalAuthors;
  final double totalValue;
  final int readCount;
  final int unreadCount;
  final Map<String, int> authorsChart;
  final List<int> availableYears;
  final List<ReadingTimelineEntry> readingTimeline;

  LibraryStats({
    required this.totalBooks,
    required this.totalPages,
    required this.totalAuthors,
    required this.totalValue,
    required this.readCount,
    required this.unreadCount,
    required this.authorsChart,
    this.availableYears = const [],
    this.readingTimeline = const [],
  });

  factory LibraryStats.fromJson(Map<String, dynamic> json) {
    // Parse authors_chart as Map<String, int>
    final authorsChartJson = json['authors_chart'] as Map<String, dynamic>? ?? {};
    final authorsChart = Map<String, int>.from(
      authorsChartJson.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
    );

    // Parse available_years as List<int>
    List<int> availableYears = [];
    if (json['available_years'] != null && json['available_years'] is List) {
      availableYears = (json['available_years'] as List)
          .map((year) => (year as num?)?.toInt() ?? 0)
          .where((year) => year > 0)
          .toList();
    }

    // Parse reading_timeline as List<ReadingTimelineEntry>
    List<ReadingTimelineEntry> readingTimeline = [];
    if (json['reading_timeline'] != null && json['reading_timeline'] is List) {
      readingTimeline = (json['reading_timeline'] as List)
          .map((entry) => ReadingTimelineEntry.fromJson(entry as Map<String, dynamic>))
          .where((entry) => entry.year > 0)
          .toList();
    }

    return LibraryStats(
      totalBooks: (json['total_books'] as int?) ?? 0,
      totalPages: (json['total_pages'] as int?) ?? 0,
      totalAuthors: (json['total_authors'] as int?) ?? 0,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
      readCount: (json['read_count'] as int?) ?? 0,
      unreadCount: (json['unread_count'] as int?) ?? 0,
      authorsChart: authorsChart,
      availableYears: availableYears,
      readingTimeline: readingTimeline,
    );
  }

  double get readPercentage {
    final total = readCount + unreadCount;
    if (total == 0) return 0.0;
    return (readCount / total) * 100;
  }
}
