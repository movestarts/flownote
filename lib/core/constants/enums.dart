enum TradeDirection {
  long(dbCode: 'L', displayName: 'Long'),
  short(dbCode: 'S', displayName: 'Short'),
  observe(dbCode: 'O', displayName: 'Observe');

  final String dbCode;
  final String displayName;

  const TradeDirection({
    required this.dbCode,
    required this.displayName,
  });

  static TradeDirection? fromDbCode(String? dbCode) {
    if (dbCode == null) return null;
    return TradeDirection.values.firstWhere(
      (e) => e.dbCode == dbCode,
      orElse: () => TradeDirection.observe,
    );
  }

  static TradeDirection? fromName(String? value) {
    if (value == null) return null;
    return TradeDirection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TradeDirection.observe,
    );
  }
}

enum TradeResult {
  profit(dbCode: 'P', displayName: 'Profit'),
  loss(dbCode: 'L', displayName: 'Loss'),
  observe(dbCode: 'O', displayName: 'Observe'),
  missed(dbCode: 'M', displayName: 'Missed');

  final String dbCode;
  final String displayName;

  const TradeResult({
    required this.dbCode,
    required this.displayName,
  });

  static TradeResult? fromDbCode(String? dbCode) {
    if (dbCode == null) return null;
    return TradeResult.values.firstWhere(
      (e) => e.dbCode == dbCode,
      orElse: () => TradeResult.observe,
    );
  }

  static TradeResult? fromName(String? value) {
    if (value == null) return null;
    return TradeResult.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TradeResult.observe,
    );
  }
}

enum TagCategory {
  type(dbCode: 'T', displayName: 'Type'),
  symbol(dbCode: 'S', displayName: 'Symbol'),
  timeframe(dbCode: 'F', displayName: 'Timeframe'),
  result(dbCode: 'R', displayName: 'Result');

  final String dbCode;
  final String displayName;

  const TagCategory({
    required this.dbCode,
    required this.displayName,
  });

  static TagCategory fromDbCode(String dbCode) {
    return TagCategory.values.firstWhere(
      (e) => e.dbCode == dbCode,
      orElse: () => TagCategory.type,
    );
  }

  static TagCategory fromName(String value) {
    return TagCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TagCategory.type,
    );
  }
}
