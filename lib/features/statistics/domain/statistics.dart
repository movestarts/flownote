import 'package:chart_flow/core/domain/entities.dart';

class CategoryCount {
  final String label;
  final int count;

  const CategoryCount({
    required this.label,
    required this.count,
  });
}

class NoteClassificationStats {
  final int totalNotes;
  final int favorites;
  final int withTags;
  final int withTitle;
  final int withContent;
  final int withSymbol;
  final int withTimeframe;
  final List<CategoryCount> topTags;
  final List<CategoryCount> topSymbols;
  final List<CategoryCount> topTimeframes;
  final Map<int, int> weekdayCounts;

  const NoteClassificationStats({
    required this.totalNotes,
    required this.favorites,
    required this.withTags,
    required this.withTitle,
    required this.withContent,
    required this.withSymbol,
    required this.withTimeframe,
    required this.topTags,
    required this.topSymbols,
    required this.topTimeframes,
    required this.weekdayCounts,
  });

  const NoteClassificationStats.empty()
      : totalNotes = 0,
        favorites = 0,
        withTags = 0,
        withTitle = 0,
        withContent = 0,
        withSymbol = 0,
        withTimeframe = 0,
        topTags = const [],
        topSymbols = const [],
        topTimeframes = const [],
        weekdayCounts = const {};

  factory NoteClassificationStats.fromNotes(List<Note> notes) {
    if (notes.isEmpty) return const NoteClassificationStats.empty();

    final tagMap = <String, int>{};
    final symbolMap = <String, int>{};
    final timeframeMap = <String, int>{};
    final weekdayMap = <int, int>{};

    int favorites = 0;
    int withTags = 0;
    int withTitle = 0;
    int withContent = 0;
    int withSymbol = 0;
    int withTimeframe = 0;

    for (final note in notes) {
      if (note.isFavorite) favorites++;
      if (note.tagNames.isNotEmpty) withTags++;
      if ((note.title ?? '').trim().isNotEmpty) withTitle++;
      if ((note.content ?? '').trim().isNotEmpty) withContent++;
      if ((note.symbol ?? '').trim().isNotEmpty) withSymbol++;
      if ((note.timeframe ?? '').trim().isNotEmpty) withTimeframe++;

      for (final tag in note.tagNames) {
        final key = tag.trim();
        if (key.isEmpty) continue;
        tagMap[key] = (tagMap[key] ?? 0) + 1;
      }

      final symbol = (note.symbol ?? '').trim();
      if (symbol.isNotEmpty) {
        symbolMap[symbol] = (symbolMap[symbol] ?? 0) + 1;
      }

      final timeframe = (note.timeframe ?? '').trim();
      if (timeframe.isNotEmpty) {
        timeframeMap[timeframe] = (timeframeMap[timeframe] ?? 0) + 1;
      }

      final weekday = note.createdAt.weekday;
      weekdayMap[weekday] = (weekdayMap[weekday] ?? 0) + 1;
    }

    List<CategoryCount> toTop(Map<String, int> source) {
      return source.entries
          .map((e) => CategoryCount(label: e.key, count: e.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));
    }

    return NoteClassificationStats(
      totalNotes: notes.length,
      favorites: favorites,
      withTags: withTags,
      withTitle: withTitle,
      withContent: withContent,
      withSymbol: withSymbol,
      withTimeframe: withTimeframe,
      topTags: toTop(tagMap),
      topSymbols: toTop(symbolMap),
      topTimeframes: toTop(timeframeMap),
      weekdayCounts: weekdayMap,
    );
  }
}
