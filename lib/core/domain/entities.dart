class Note {
  final String id;
  final String imagePath;
  final String? title;
  final String? content;
  final String? symbol;
  final String? timeframe;
  final String? direction; // L/S/O (Long/Short/Observe)
  final String? result; // P/L/O/M (Profit/Loss/Observe/Missed)
  final double? profitPoints; // 盈亏点数
  final DateTime? tradeTime;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<String> tagIds;
  final List<String> tagNames;

  const Note({
    required this.id,
    required this.imagePath,
    this.title,
    this.content,
    this.symbol,
    this.timeframe,
    this.direction,
    this.result,
    this.profitPoints,
    this.tradeTime,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.tagIds = const [],
    this.tagNames = const [],
  });

  Note copyWith({
    String? id,
    String? imagePath,
    String? title,
    String? content,
    String? symbol,
    String? timeframe,
    String? direction,
    String? result,
    double? profitPoints,
    DateTime? tradeTime,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<String>? tagIds,
    List<String>? tagNames,
  }) {
    return Note(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      title: title ?? this.title,
      content: content ?? this.content,
      symbol: symbol ?? this.symbol,
      timeframe: timeframe ?? this.timeframe,
      direction: direction ?? this.direction,
      result: result ?? this.result,
      profitPoints: profitPoints ?? this.profitPoints,
      tradeTime: tradeTime ?? this.tradeTime,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      tagIds: tagIds ?? this.tagIds,
      tagNames: tagNames ?? this.tagNames,
    );
  }
}

class Tag {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tag({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  Tag copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SavedFilter {
  final String id;
  final String name;
  final String filterPayloadJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedFilter({
    required this.id,
    required this.name,
    required this.filterPayloadJson,
    required this.createdAt,
    required this.updatedAt,
  });

  SavedFilter copyWith({
    String? id,
    String? name,
    String? filterPayloadJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      filterPayloadJson: filterPayloadJson ?? this.filterPayloadJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NoteQuery {
  final List<String> tagIds;
  final List<String> symbols;
  final List<String> timeframes;
  final bool? favoriteOnly;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? keyword;

  const NoteQuery({
    this.tagIds = const [],
    this.symbols = const [],
    this.timeframes = const [],
    this.favoriteOnly,
    this.startTime,
    this.endTime,
    this.keyword,
  });

  NoteQuery copyWith({
    List<String>? tagIds,
    List<String>? symbols,
    List<String>? timeframes,
    bool? favoriteOnly,
    DateTime? startTime,
    DateTime? endTime,
    String? keyword,
  }) {
    return NoteQuery(
      tagIds: tagIds ?? this.tagIds,
      symbols: symbols ?? this.symbols,
      timeframes: timeframes ?? this.timeframes,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      keyword: keyword ?? this.keyword,
    );
  }

  bool get isEmpty =>
      tagIds.isEmpty &&
      symbols.isEmpty &&
      timeframes.isEmpty &&
      favoriteOnly == null &&
      startTime == null &&
      endTime == null &&
      keyword == null;
}
