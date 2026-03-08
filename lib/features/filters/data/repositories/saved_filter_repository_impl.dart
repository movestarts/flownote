import 'package:chart_flow/core/data/database/database.dart' show AppDatabase;
import 'package:chart_flow/core/data/dao/saved_filter_dao.dart';
import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/filters/domain/repositories/saved_filter_repository.dart';

class SavedFilterRepositoryImpl implements SavedFilterRepository {
  final AppDatabase _db;
  late final SavedFilterDao _savedFilterDao;

  SavedFilterRepositoryImpl(this._db) {
    _savedFilterDao = SavedFilterDao(_db);
  }

  @override
  Future<List<SavedFilter>> getAllSavedFilters() =>
      _savedFilterDao.getAllSavedFilters();

  @override
  Future<SavedFilter?> getSavedFilterById(String id) =>
      _savedFilterDao.getSavedFilterById(id);

  @override
  Future<void> createSavedFilter(SavedFilter filter) =>
      _savedFilterDao.createSavedFilterEntry(filter);

  @override
  Future<void> updateSavedFilter(SavedFilter filter) =>
      _savedFilterDao.updateSavedFilterEntry(filter);

  @override
  Future<void> deleteSavedFilter(String id) =>
      _savedFilterDao.deleteSavedFilterById(id);
}
