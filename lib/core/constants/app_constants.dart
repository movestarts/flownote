class AppConstants {
  AppConstants._();

  static const String appName = '图流复盘';
  static const String appVersion = '1.0.0';

  static const List<String> defaultTimeframes = [
    '5m',
    '15m',
    '30m',
    '60m',
    '1d'
  ];
  static const List<String> defaultSymbols = [
    'RB',
    'FG',
    'M',
    'I',
    'HC',
    'J',
    'JM',
    'P',
    'Y',
    'A'
  ];
  static const List<String> defaultDirections = ['long', 'short', 'observe'];
  static const List<String> defaultResults = [
    'profit',
    'loss',
    'observe',
    'missed'
  ];

  static const int maxRecentItems = 10;
  static const int defaultPageSize = 20;
}
