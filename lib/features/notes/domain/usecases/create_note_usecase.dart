import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/core/services/local_file_service.dart';
import 'package:chart_flow/features/notes/domain/repositories/note_repository.dart';

class CreateNoteUseCase {
  final NoteRepository _noteRepository;
  final LocalFileService _fileService;

  CreateNoteUseCase({
    required NoteRepository noteRepository,
    required LocalFileService fileService,
  })  : _noteRepository = noteRepository,
        _fileService = fileService;

  Future<Note> execute({
    required String sourceImagePath,
    List<String> tagIds = const [],
    String? title,
    String? content,
    String? symbol,
    String? timeframe,
    DateTime? tradeTime,
    bool isFavorite = false,
  }) async {
    final localImagePath =
        await _fileService.copyImageToAppDirectory(sourceImagePath);

    final now = DateTime.now();
    final newNote = Note(
      id: _generateId(),
      imagePath: localImagePath,
      title: title,
      content: content,
      symbol: symbol,
      timeframe: timeframe,
      tradeTime: tradeTime,
      isFavorite: isFavorite,
      createdAt: now,
      updatedAt: now,
      tagIds: tagIds,
    );

    await _noteRepository.createNote(newNote);
    return newNote;
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
