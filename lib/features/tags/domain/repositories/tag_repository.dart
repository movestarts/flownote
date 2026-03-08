import 'package:chart_flow/core/domain/entities.dart';

abstract class TagRepository {
  Future<List<Tag>> getAllTags();
  Future<Tag?> getTagById(String id);
  Future<Tag?> getTagByName(String name);
  Future<void> createTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(String id);
  Future<bool> isTagUsedInNotes(String tagId);
  Future<int> getNoteCountByTagId(String tagId);
  Future<void> safeDeleteTag(String id);
}
