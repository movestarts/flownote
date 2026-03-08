import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/filters/data/repositories/saved_filter_repository_impl.dart';
import 'package:chart_flow/features/filters/domain/repositories/saved_filter_repository.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';
import 'package:chart_flow/features/tags/providers/tag_providers.dart';
import 'package:chart_flow/shared/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterOptions {
  final List<Tag> tags;
  final List<String> symbols;
  final List<String> timeframes;

  const FilterOptions({
    this.tags = const [],
    this.symbols = const [],
    this.timeframes = const [],
  });
}

final savedFilterRepositoryProvider = Provider<SavedFilterRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SavedFilterRepositoryImpl(db);
});

final filterOptionsProvider = FutureProvider<FilterOptions>((ref) async {
  ref.watch(notesRefreshTickProvider);

  final tagRepository = ref.watch(tagRepositoryProvider);
  final noteRepository = ref.watch(noteRepositoryProvider);

  final tags = await tagRepository.getAllTags();
  final notes = await noteRepository.getAllNotes();

  final symbols = {
    ...notes
        .map((e) => e.symbol)
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty),
  }.toList()
    ..sort();

  final timeframes = {
    ...notes
        .map((e) => e.timeframe)
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty),
  }.toList()
    ..sort();

  return FilterOptions(tags: tags, symbols: symbols, timeframes: timeframes);
});
