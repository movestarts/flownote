import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:chart_flow/features/tags/domain/repositories/tag_repository.dart';
import 'package:chart_flow/shared/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TagRepositoryImpl(db);
});

final allTagsProvider = FutureProvider<List<Tag>>((ref) async {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getAllTags();
});
