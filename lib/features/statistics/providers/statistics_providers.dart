import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';
import 'package:chart_flow/features/statistics/domain/statistics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<Note> _filterNotesByRange(
  List<Note> notes, {
  required DateTime from,
}) {
  return notes
      .where((n) => n.createdAt.isAfter(from) || n.createdAt.isAtSameMomentAs(from))
      .toList();
}

final todayStatisticsProvider =
    FutureProvider<NoteClassificationStats>((ref) async {
  final notes = await ref.watch(allNotesProvider.future);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  return NoteClassificationStats.fromNotes(
    _filterNotesByRange(notes, from: todayStart),
  );
});

final thisWeekStatisticsProvider =
    FutureProvider<NoteClassificationStats>((ref) async {
  final notes = await ref.watch(allNotesProvider.future);
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  return NoteClassificationStats.fromNotes(
    _filterNotesByRange(notes, from: monday),
  );
});

final weekStatisticsProvider = thisWeekStatisticsProvider;

final thisMonthStatisticsProvider =
    FutureProvider<NoteClassificationStats>((ref) async {
  final notes = await ref.watch(allNotesProvider.future);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  return NoteClassificationStats.fromNotes(
    _filterNotesByRange(notes, from: monthStart),
  );
});
