import 'package:chart_flow/core/data/database/database.dart';
import 'package:chart_flow/core/domain/entities.dart' as domain;
import 'package:drift/drift.dart';

part 'saved_filter_dao.g.dart';

@DriftAccessor(tables: [SavedFilters])
class SavedFilterDao extends DatabaseAccessor<AppDatabase>
    with _$SavedFilterDaoMixin {
  SavedFilterDao(super.db);

  Future<List<domain.SavedFilter>> getAllSavedFilters() async {
    final rows = await (select(db.savedFilters)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<domain.SavedFilter?> getSavedFilterById(String id) async {
    final row = await (select(db.savedFilters)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  Future<void> createSavedFilterEntry(domain.SavedFilter filter) async {
    await into(db.savedFilters).insert(_toCompanion(filter));
  }

  Future<void> updateSavedFilterEntry(domain.SavedFilter filter) async {
    await (update(db.savedFilters)..where((t) => t.id.equals(filter.id))).write(
      SavedFiltersCompanion(
        name: Value(filter.name),
        filterPayloadJson: Value(filter.filterPayloadJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSavedFilterById(String id) async {
    await (delete(db.savedFilters)..where((t) => t.id.equals(id))).go();
  }

  domain.SavedFilter _toDomain(SavedFilter row) {
    return domain.SavedFilter(
      id: row.id,
      name: row.name,
      filterPayloadJson: row.filterPayloadJson,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  SavedFiltersCompanion _toCompanion(domain.SavedFilter filter) {
    return SavedFiltersCompanion(
      id: Value(filter.id),
      name: Value(filter.name),
      filterPayloadJson: Value(filter.filterPayloadJson),
      createdAt: Value(filter.createdAt),
      updatedAt: Value(filter.updatedAt),
    );
  }
}
