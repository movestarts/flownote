import 'package:chart_flow/core/data/database/database.dart';
import 'package:drift/drift.dart';

part 'recent_usage_dao.g.dart';

@DriftAccessor(tables: [RecentUsages])
class RecentUsageDao extends DatabaseAccessor<AppDatabase>
    with _$RecentUsageDaoMixin {
  RecentUsageDao(super.db);

  Future<List<String>> getRecentFieldValues(String fieldName,
      {int limit = 10}) async {
    final rows = await (select(db.recentUsages)
          ..where((t) => t.fieldName.equals(fieldName))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .get();
    return rows.map((e) => e.fieldValue).toList();
  }

  Future<void> recordUsage(String fieldName, String fieldValue) async {
    await deleteFieldValue(fieldName, fieldValue);

    await into(db.recentUsages).insert(
      RecentUsagesCompanion.insert(
        id: '${fieldName}_$fieldValue',
        fieldName: fieldName,
        fieldValue: fieldValue,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> deleteFieldValue(String fieldName, String fieldValue) async {
    await (delete(db.recentUsages)
          ..where((t) =>
              t.fieldName.equals(fieldName) & t.fieldValue.equals(fieldValue)))
        .go();
  }

  Future<void> clearField(String fieldName) async {
    await (delete(db.recentUsages)..where((t) => t.fieldName.equals(fieldName)))
        .go();
  }

  Future<void> clearAll() async {
    await delete(db.recentUsages).go();
  }
}
