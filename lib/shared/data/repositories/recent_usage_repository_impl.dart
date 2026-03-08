import 'package:chart_flow/core/data/database/database.dart';
import 'package:chart_flow/core/data/dao/recent_usage_dao.dart';
import 'package:chart_flow/shared/domain/repositories/recent_usage_repository.dart';

class RecentUsageRepositoryImpl implements RecentUsageRepository {
  final AppDatabase _db;
  late final RecentUsageDao _recentUsageDao;

  RecentUsageRepositoryImpl(this._db) {
    _recentUsageDao = RecentUsageDao(_db);
  }

  @override
  Future<List<String>> getRecentFieldValues(String fieldName,
          {int limit = 10}) =>
      _recentUsageDao.getRecentFieldValues(fieldName, limit: limit);

  @override
  Future<void> recordUsage(String fieldName, String fieldValue) =>
      _recentUsageDao.recordUsage(fieldName, fieldValue);

  @override
  Future<void> deleteFieldValue(String fieldName, String fieldValue) =>
      _recentUsageDao.deleteFieldValue(fieldName, fieldValue);

  @override
  Future<void> clearField(String fieldName) =>
      _recentUsageDao.clearField(fieldName);

  @override
  Future<void> clearAll() => _recentUsageDao.clearAll();
}
