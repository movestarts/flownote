import 'dart:io';
import 'package:chart_flow/core/services/local_file_service.dart';
import 'package:chart_flow/features/notes/domain/repositories/note_repository.dart';

class CleanupService {
  final LocalFileService _fileService;
  final NoteRepository _noteRepository;

  CleanupService({
    required LocalFileService fileService,
    required NoteRepository noteRepository,
  })  : _fileService = fileService,
        _noteRepository = noteRepository;

  Future<List<String>> findOrphanedImages() async {
    final storedImages = await _fileService.getAllStoredImages();
    final notes = await _noteRepository.getAllNotes();
    final usedImagePaths = notes.map((n) => n.imagePath).toSet();

    final orphanedImages =
        storedImages.where((path) => !usedImagePaths.contains(path)).toList();

    return orphanedImages;
  }

  Future<int> cleanupOrphanedImages({int maxAgeDays = 7}) async {
    final orphanedImages = await findOrphanedImages();
    final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));

    int deletedCount = 0;

    for (final imagePath in orphanedImages) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await _fileService.deleteImage(imagePath);
            deletedCount++;
          }
        }
      } catch (e) {
        continue;
      }
    }

    return deletedCount;
  }

  Future<void> cleanupMissingImageReferences() async {
    final notes = await _noteRepository.getAllNotes();

    for (final note in notes) {
      final exists = await _fileService.imageExists(note.imagePath);
      if (!exists) {}
    }
  }
}
