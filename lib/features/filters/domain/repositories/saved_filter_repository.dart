import 'package:chart_flow/core/domain/entities.dart';

abstract class SavedFilterRepository {
  Future<List<SavedFilter>> getAllSavedFilters();
  Future<SavedFilter?> getSavedFilterById(String id);
  Future<void> createSavedFilter(SavedFilter filter);
  Future<void> updateSavedFilter(SavedFilter filter);
  Future<void> deleteSavedFilter(String id);
}
