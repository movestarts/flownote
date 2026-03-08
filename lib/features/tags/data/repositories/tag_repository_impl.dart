import 'package:chart_flow/core/data/database/database.dart' show AppDatabase;
import 'package:chart_flow/core/data/dao/tag_dao.dart';
import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/core/errors/exceptions.dart';
import 'package:chart_flow/features/tags/domain/repositories/tag_repository.dart';

class TagRepositoryImpl implements TagRepository {
  final AppDatabase _db;
  late final TagDao _tagDao;

  TagRepositoryImpl(this._db) {
    _tagDao = TagDao(_db);
  }

  @override
  Future<List<Tag>> getAllTags() => _tagDao.getAllTags();

  @override
  Future<Tag?> getTagById(String id) => _tagDao.getTagById(id);

  @override
  Future<Tag?> getTagByName(String name) => _tagDao.getTagByName(name);

  @override
  Future<void> createTag(Tag tag) => _tagDao.createTagEntry(tag);

  @override
  Future<void> updateTag(Tag tag) => _tagDao.updateTagEntry(tag);

  @override
  Future<void> deleteTag(String id) => _tagDao.deleteTagById(id);

  @override
  Future<bool> isTagUsedInNotes(String tagId) =>
      _tagDao.isTagUsedInNotes(tagId);

  @override
  Future<int> getNoteCountByTagId(String tagId) async {
    final rows = await (_db.select(_db.noteTags)..where((t) => t.tagId.equals(tagId))).get();
    return rows.length;
  }

  @override
  Future<void> safeDeleteTag(String id) async {
    final noteCount = await getNoteCountByTagId(id);

    if (noteCount > 0) {
      throw TagInUseException(tagId: id, noteCount: noteCount);
    }

    await deleteTag(id);
  }
}
