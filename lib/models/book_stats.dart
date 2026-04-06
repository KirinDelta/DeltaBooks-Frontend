class ReadingTimelineEntry {
  final int year;
  final int books;

  ReadingTimelineEntry({
    required this.year,
    required this.books,
  });

  factory ReadingTimelineEntry.fromJson(Map<String, dynamic> json) {
    return ReadingTimelineEntry(
      year: (json['year'] as num?)?.toInt() ?? 0,
      books: (json['books'] as num?)?.toInt() ?? 0,
    );
  }
}

class BookStats {
  final int totalBooks;
  final int totalPages;
  final double totalValue;
  final List<int> availableYears;
  final Map<String, int> authorsChart;
  final List<ReadingTimelineEntry> readingTimeline;

  BookStats({
    required this.totalBooks,
    required this.totalPages,
    required this.totalValue,
    required this.availableYears,
    required this.authorsChart,
    this.readingTimeline = const [],
  });

  factory BookStats.fromJson(Map<String, dynamic> json) {
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

    return BookStats(
      totalBooks: (json['total_books'] as int?) ?? 0,
      totalPages: (json['total_pages'] as int?) ?? 0,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
      availableYears: availableYears,
      authorsChart: authorsChart,
      readingTimeline: readingTimeline,
    );
  }
}
