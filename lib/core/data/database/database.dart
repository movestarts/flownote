import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'tables.dart';
part 'database.g.dart';

@DriftDatabase(tables: [Notes, Tags, NoteTags, SavedFilters, RecentUsages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await customStatement('DROP TABLE IF EXISTS note_tags;');
          await customStatement('DROP TABLE IF EXISTS notes;');
          await customStatement('DROP TABLE IF EXISTS tags;');
          await customStatement('DROP TABLE IF EXISTS saved_filters;');
          await customStatement('DROP TABLE IF EXISTS recent_usages;');
          await m.createAll();
        }
      },
    );
  }

  Future<void> initialize() async {
    await select(notes).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'chart_flow.db'));
    return NativeDatabase.createInBackground(file);
  });
}
