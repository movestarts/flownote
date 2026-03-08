import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chart_flow/core/data/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
