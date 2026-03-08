import 'package:chart_flow/core/domain/entities.dart';

abstract class NoteRepository {
  Future<List<Note>> getAllNotes();
  Future<Note?> getNoteById(String id);
  Future<List<Note>> queryNotes(NoteQuery query);
  Future<List<Note>> getRecentNotes({int limit = 10});
  Future<List<Note>> getFavoriteNotes();
  Future<void> createNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String id);
  Future<void> toggleFavorite(String id);
  Future<int> getNoteCountByTagId(String tagId);
}
