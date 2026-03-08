import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chart_flow/shared/providers/database_provider.dart';
import 'package:chart_flow/shared/domain/repositories/recent_usage_repository.dart';
import 'package:chart_flow/shared/data/repositories/recent_usage_repository_impl.dart';

final recentUsageRepositoryProvider = Provider<RecentUsageRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return RecentUsageRepositoryImpl(db);
});
