import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chart_flow/core/services/local_file_service.dart';
import 'package:chart_flow/core/services/cleanup_service.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';

final localFileServiceProvider = Provider<LocalFileService>((ref) {
  return LocalFileService();
});

final cleanupServiceProvider = Provider<CleanupService>((ref) {
  final fileService = ref.watch(localFileServiceProvider);
  final noteRepository = ref.watch(noteRepositoryProvider);
  return CleanupService(
    fileService: fileService,
    noteRepository: noteRepository,
  );
});
