import 'dart:convert';
import 'package:drift/drift.dart';

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final decoded = jsonDecode(fromDb);
      return List<String>.from(decoded);
    } catch (e) {
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    if (value.isEmpty) return '[]';
    return jsonEncode(value);
  }
}
