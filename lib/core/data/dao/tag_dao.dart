import 'package:chart_flow/core/data/database/database.dart';
import 'package:chart_flow/core/domain/entities.dart' as domain;
import 'package:drift/drift.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags, NoteTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Future<List<domain.Tag>> getAllTags() async {
    final rows = await (select(db.tags)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<domain.Tag?> getTagById(String id) async {
    final row = await (select(db.tags)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  Future<domain.Tag?> getTagByName(String name) async {
    final row = await (select(db.tags)..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  Future<void> createTagEntry(domain.Tag tag) async {
    await into(db.tags).insert(_toCompanion(tag));
  }

  Future<void> updateTagEntry(domain.Tag tag) async {
    await (update(db.tags)..where((t) => t.id.equals(tag.id))).write(
      TagsCompanion(
        name: Value(tag.name),
        color: Value(tag.color),
        icon: Value(tag.icon),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteTagById(String id) async {
    await (delete(db.tags)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> isTagUsedInNotes(String tagId) async {
    final row = await (select(db.noteTags)..where((t) => t.tagId.equals(tagId)))
        .getSingleOrNull();
    return row != null;
  }

  domain.Tag _toDomain(Tag row) {
    return domain.Tag(
      id: row.id,
      name: row.name,
      color: row.color,
      icon: row.icon,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TagsCompanion _toCompanion(domain.Tag tag) {
    return TagsCompanion(
      id: Value(tag.id),
      name: Value(tag.name),
      color: Value(tag.color),
      icon: Value(tag.icon),
      createdAt: Value(tag.createdAt),
      updatedAt: Value(tag.updatedAt),
    );
  }
}
