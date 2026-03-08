import 'package:chart_flow/core/data/database/database.dart';
import 'package:chart_flow/core/domain/entities.dart' as domain;
import 'package:drift/drift.dart';

part 'note_dao.g.dart';

@DriftAccessor(tables: [Notes, Tags, NoteTags])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  Future<List<domain.Note>> getAllNotes() async {
    final rows = await (select(db.notes)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return _mapNotesWithTags(rows);
  }

  Future<domain.Note?> getNoteById(String id) async {
    final row = await (select(db.notes)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;
    final mapped = await _mapNotesWithTags([row]);
    return mapped.isEmpty ? null : mapped.first;
  }

  Future<List<domain.Note>> queryNotes(domain.NoteQuery query) async {
    final stmt = select(db.notes);

    stmt.where((t) {
      final conditions = <Expression<bool>>[t.deletedAt.isNull()];

      if (query.symbols.isNotEmpty) {
        conditions.add(t.symbol.isIn(query.symbols));
      }
      if (query.timeframes.isNotEmpty) {
        conditions.add(t.timeframe.isIn(query.timeframes));
      }
      if (query.favoriteOnly == true) {
        conditions.add(t.isFavorite.equals(true));
      }
      if (query.startTime != null) {
        conditions.add(t.tradeTime.isBiggerOrEqualValue(query.startTime!));
      }
      if (query.endTime != null) {
        conditions.add(t.tradeTime.isSmallerOrEqualValue(query.endTime!));
      }
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final keyword = '%${query.keyword}%';
        conditions.add(t.title.like(keyword) | t.content.like(keyword));
      }
      return conditions.reduce((a, b) => a & b);
    });

    stmt.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    final rows = await stmt.get();
    final notes = await _mapNotesWithTags(rows);
    if (query.tagIds.isEmpty) return notes;
    return notes
        .where((note) =>
            query.tagIds.every((tagId) => note.tagIds.contains(tagId)))
        .toList();
  }

  Future<List<domain.Note>> getRecentNotes({int limit = 10}) async {
    final rows = await (select(db.notes)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return _mapNotesWithTags(rows);
  }

  Future<List<domain.Note>> getFavoriteNotes() async {
    final rows = await (select(db.notes)
          ..where((t) => t.isFavorite.equals(true) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return _mapNotesWithTags(rows);
  }

  Future<void> createNoteEntry(domain.Note note) async {
    await transaction(() async {
      await into(db.notes).insert(_toCompanion(note));
      if (note.tagIds.isNotEmpty) {
        await batch((b) {
          b.insertAll(
            db.noteTags,
            note.tagIds
                .map(
                  (tagId) => NoteTagsCompanion.insert(
                    noteId: note.id,
                    tagId: tagId,
                  ),
                )
                .toList(),
          );
        });
      }
    });
  }

  Future<void> updateNoteEntry(domain.Note note) async {
    await transaction(() async {
      await (update(db.notes)..where((t) => t.id.equals(note.id))).write(
        NotesCompanion(
          imagePath: Value(note.imagePath),
          title: Value(note.title),
          content: Value(note.content),
          symbol: Value(note.symbol),
          timeframe: Value(note.timeframe),
          tradeTime: Value(note.tradeTime),
          isFavorite: Value(note.isFavorite),
          updatedAt: Value(DateTime.now()),
          deletedAt: Value(note.deletedAt),
        ),
      );

      await (delete(db.noteTags)..where((t) => t.noteId.equals(note.id))).go();
      if (note.tagIds.isNotEmpty) {
        await batch((b) {
          b.insertAll(
            db.noteTags,
            note.tagIds
                .map(
                  (tagId) => NoteTagsCompanion.insert(
                    noteId: note.id,
                    tagId: tagId,
                  ),
                )
                .toList(),
          );
        });
      }
    });
  }

  Future<void> deleteNoteById(String id) async {
    await (update(db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> toggleFavorite(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await updateNoteEntry(note.copyWith(isFavorite: !note.isFavorite));
    }
  }

  Future<int> getNoteCountByTagId(String tagId) async {
    final rows =
        await (select(db.noteTags)..where((t) => t.tagId.equals(tagId))).get();
    final noteIds = rows.map((e) => e.noteId).toSet();
    if (noteIds.isEmpty) return 0;

    final countExpr = db.notes.id.count();
    final query = selectOnly(db.notes)
      ..addColumns([countExpr])
      ..where(db.notes.id.isIn(noteIds) & db.notes.deletedAt.isNull());
    final result = await query.getSingle();
    return result.read(countExpr) ?? 0;
  }

  Future<List<domain.Note>> _mapNotesWithTags(List<Note> rows) async {
    if (rows.isEmpty) return [];

    final noteIds = rows.map((e) => e.id).toSet().toList();
    final joins = await (select(db.noteTags)
          ..where((nt) => nt.noteId.isIn(noteIds)))
        .join([
      leftOuterJoin(db.tags, db.tags.id.equalsExp(db.noteTags.tagId)),
    ]).get();

    final tagIdsByNote = <String, List<String>>{};
    final tagNamesByNote = <String, List<String>>{};

    for (final row in joins) {
      final noteTag = row.readTable(db.noteTags);
      final tag = row.readTableOrNull(db.tags);
      tagIdsByNote.putIfAbsent(noteTag.noteId, () => []).add(noteTag.tagId);
      if (tag != null) {
        tagNamesByNote.putIfAbsent(noteTag.noteId, () => []).add(tag.name);
      }
    }

    return rows
        .map((row) => _toDomain(
            row, tagIdsByNote[row.id] ?? [], tagNamesByNote[row.id] ?? []))
        .toList();
  }

  domain.Note _toDomain(Note row, List<String> tagIds, List<String> tagNames) {
    return domain.Note(
      id: row.id,
      imagePath: row.imagePath,
      title: row.title,
      content: row.content,
      symbol: row.symbol,
      timeframe: row.timeframe,
      tradeTime: row.tradeTime,
      isFavorite: row.isFavorite,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      tagIds: tagIds,
      tagNames: tagNames,
    );
  }

  NotesCompanion _toCompanion(domain.Note note) {
    return NotesCompanion(
      id: Value(note.id),
      imagePath: Value(note.imagePath),
      title: Value(note.title),
      content: Value(note.content),
      symbol: Value(note.symbol),
      timeframe: Value(note.timeframe),
      tradeTime: Value(note.tradeTime),
      isFavorite: Value(note.isFavorite),
      createdAt: Value(note.createdAt),
      updatedAt: Value(note.updatedAt),
      deletedAt: Value(note.deletedAt),
    );
  }
}
