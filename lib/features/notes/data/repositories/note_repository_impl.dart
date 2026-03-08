import 'package:chart_flow/core/data/database/database.dart' show AppDatabase;
import 'package:chart_flow/core/data/dao/note_dao.dart';
import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/notes/domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final AppDatabase _db;
  late final NoteDao _noteDao;

  NoteRepositoryImpl(this._db) {
    _noteDao = NoteDao(_db);
  }

  @override
  Future<List<Note>> getAllNotes() => _noteDao.getAllNotes();

  @override
  Future<Note?> getNoteById(String id) => _noteDao.getNoteById(id);

  @override
  Future<List<Note>> queryNotes(NoteQuery query) => _noteDao.queryNotes(query);

  @override
  Future<List<Note>> getRecentNotes({int limit = 10}) =>
      _noteDao.getRecentNotes(limit: limit);

  @override
  Future<List<Note>> getFavoriteNotes() => _noteDao.getFavoriteNotes();

  @override
  Future<void> createNote(Note note) => _noteDao.createNoteEntry(note);

  @override
  Future<void> updateNote(Note note) => _noteDao.updateNoteEntry(note);

  @override
  Future<void> deleteNote(String id) => _noteDao.deleteNoteById(id);

  @override
  Future<void> toggleFavorite(String id) => _noteDao.toggleFavorite(id);

  @override
  Future<int> getNoteCountByTagId(String tagId) =>
      _noteDao.getNoteCountByTagId(tagId);
}
