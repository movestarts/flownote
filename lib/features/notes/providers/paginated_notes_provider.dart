import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/notes/domain/repositories/note_repository.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaginatedNotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NoteRepository _repository;
  final NoteQuery _query;
  final int _pageSize;

  List<Note> _allNotes = [];
  int _currentPage = 0;
  bool _hasMore = true;

  PaginatedNotesNotifier({
    required NoteRepository repository,
    required NoteQuery query,
    int pageSize = 20,
  })  : _repository = repository,
        _query = query,
        _pageSize = pageSize,
        super(const AsyncValue.loading()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    try {
      _allNotes = await _repository.queryNotes(_query);
      _currentPage = 0;
      _hasMore = _allNotes.length > _pageSize;
      state = AsyncValue.data(_allNotes.take(_pageSize).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;

    _currentPage++;

    final endIndex = (_currentPage + 1) * _pageSize;
    if (endIndex >= _allNotes.length) {
      _hasMore = false;
      state = AsyncValue.data(_allNotes);
      return;
    }

    state = AsyncValue.data(_allNotes.sublist(0, endIndex));
  }

  bool get hasMore => _hasMore;

  int get totalCount => _allNotes.length;

  Note? getNoteAt(int index) {
    final notes = state.valueOrNull;
    if (notes == null || index < 0 || index >= notes.length) return null;
    return notes[index];
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final paginatedNotesProvider = StateNotifierProvider.family<
    PaginatedNotesNotifier, AsyncValue<List<Note>>, NoteQuery>((ref, query) {
  final repository = ref.watch(noteRepositoryProvider);
  return PaginatedNotesNotifier(
    repository: repository,
    query: query,
  );
});

final noteAtIndexProvider =
    Provider.family<Note?, (NoteQuery, int)>((ref, params) {
  final (query, index) = params;
  final notes = ref.watch(paginatedNotesProvider(query));
  return notes.when(
    data: (list) => index < list.length ? list[index] : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

final notesCountProvider = Provider.family<int, NoteQuery>((ref, query) {
  final notes = ref.watch(paginatedNotesProvider(query));
  return notes.when(
    data: (list) => list.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
