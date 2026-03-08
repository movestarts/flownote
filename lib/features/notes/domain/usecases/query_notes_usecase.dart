import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/notes/domain/repositories/note_repository.dart';

class QueryNotesUseCase {
  final NoteRepository _repository;

  QueryNotesUseCase(this._repository);

  Future<List<Note>> call(NoteQuery query) async {
    return _repository.queryNotes(query);
  }
}
