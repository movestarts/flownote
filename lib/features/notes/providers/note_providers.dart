import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/notes/data/repositories/note_repository_impl.dart';
import 'package:chart_flow/features/notes/domain/repositories/note_repository.dart';
import 'package:chart_flow/shared/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NoteRepositoryImpl(db);
});

final notesRefreshTickProvider = StateProvider<int>((ref) => 0);

final notesByQueryProvider =
    FutureProvider.family<List<Note>, NoteQuery>((ref, query) async {
  ref.watch(notesRefreshTickProvider);
  final repository = ref.watch(noteRepositoryProvider);
  return repository.queryNotes(query);
});

final recentNotesProvider = FutureProvider<List<Note>>((ref) async {
  ref.watch(notesRefreshTickProvider);
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getRecentNotes(limit: 20);
});

final favoriteNotesProvider = FutureProvider<List<Note>>((ref) async {
  ref.watch(notesRefreshTickProvider);
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getFavoriteNotes();
});
