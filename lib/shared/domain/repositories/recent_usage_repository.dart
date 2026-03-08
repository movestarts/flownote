abstract class RecentUsageRepository {
  Future<List<String>> getRecentFieldValues(String fieldName, {int limit = 10});
  Future<void> recordUsage(String fieldName, String fieldValue);
  Future<void> deleteFieldValue(String fieldName, String fieldValue);
  Future<void> clearField(String fieldName);
  Future<void> clearAll();
}
