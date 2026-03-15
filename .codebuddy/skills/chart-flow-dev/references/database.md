# Database Reference

## Overview

Chart Flow uses Drift (formerly Moor) for type-safe SQLite database access. This document covers database schema, migrations, DAOs, and common database operations.

## Database Structure

### Core Tables

#### Notes Table

The central table storing trading notes:

```dart
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get imagePath => text()();
  
  // Type tag
  TextColumn get typeTagId => text().nullable()();
  TextColumn get typeNameSnapshot => text().nullable()();
  
  // Optional fields
  TextColumn get symbol => text().nullable()();
  TextColumn get timeframe => text().nullable()();
  DateTimeColumn get tradeTime => dateTime().nullable()();
  TextColumn get direction => text().nullable()(); // L/S/O
  TextColumn get result => text().nullable()(); // P/L/O/M
  TextColumn get note => text().nullable()();
  
  // Status
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Key Design Decisions:**
- `typeTagId` references Tags table but no foreign key constraint (for flexibility)
- `typeNameSnapshot` stores tag name at creation time (prevent name changes from affecting historical data)
- `direction` and `result` use single-character codes (L/S/O, P/L/O/M)
- `favorite` and `archived` have default values for backward compatibility

#### Tags Table

Manages multi-dimensional tags:

```dart
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()(); // type/symbol/timeframe/result
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Tag Categories:**
- `type`: Trading types (breakout, pullback, range, etc.)
- `symbol`: Trading instruments (RB, FG, M, etc.)
- `timeframe`: Chart periods (5m, 15m, 30m, 1d, etc.)
- `result`: Trading outcomes (Profit, Loss, Observe, Missed)

#### SavedFilters Table

Stores user-defined filter combinations:

```dart
class SavedFilters extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  
  // Filter criteria (JSON arrays)
  TextColumn get typeIds => text().map(const StringListConverter())();
  TextColumn get symbols => text().map(const StringListConverter())();
  TextColumn get timeframes => text().map(const StringListConverter())();
  TextColumn get directions => text().map(const StringListConverter())();
  TextColumn get results => text().map(const StringListConverter())();
  
  // Additional filters
  BoolColumn get favoriteOnly => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Type Converter for Lists:**
```dart
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  
  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return List<String>.from(jsonDecode(fromDb));
  }

  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}
```

#### RecentUsages Table

Tracks recently used items for quick access:

```dart
class RecentUsages extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  TextColumn get itemId => text()();
  DateTimeColumn get usedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### Database Definition

```dart
@DriftDatabase(
  tables: [Notes, Tags, SavedFilters, RecentUsages],
  daos: [NoteDao, TagDao, SavedFilterDao, RecentUsageDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertBuiltinTags();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations here
      },
    );
  }
  
  Future<void> _insertBuiltinTags() async {
    // Insert default tags for each category
  }
}
```

## Data Access Objects (DAOs)

### NoteDao

Handles all note-related queries:

```dart
@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(AppDatabase db) : super(db);
  
  // Simple queries
  Future<List<Note>> getAllNotes() => select(notes).get();
  Future<Note?> getNoteById(String id) =>
      (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();
  
  // Complex query with filtering
  Future<List<Note>> queryNotes(NoteQuery query) {
    var stmt = select(notes)
      ..where((n) => n.archived.equals(query.archived ?? false));
    
    // Apply filters
    if (query.typeIds.isNotEmpty) {
      stmt.where((n) => n.typeTagId.isIn(query.typeIds));
    }
    if (query.symbols.isNotEmpty) {
      stmt.where((n) => n.symbol.isIn(query.symbols));
    }
    if (query.favoriteOnly == true) {
      stmt.where((n) => n.favorite.equals(true));
    }
    // ... more filters
    
    // Order by
    stmt.orderBy([(n) => OrderingTerm.desc(n.createdAt)]);
    
    // Pagination
    if (query.offset != null) {
      stmt.limit(query.limit!, offset: query.offset);
    }
    
    return stmt.get();
  }
  
  // CRUD operations
  Future<void> insertNote(Note note) => into(notes).insert(note);
  Future<void> updateNote(Note note) => update(notes).replace(note);
  Future<void> deleteNote(String id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();
  
  // Aggregations
  Future<int> countByTypeTag(String tagId) =>
      (notes.count()..where((n) => n.typeTagId.equals(tagId))).getSingle();
}
```

### TagDao

Manages tags with category filtering:

```dart
@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(AppDatabase db) : super(db);
  
  Future<List<Tag>> getTagsByCategory(String category) =>
      (select(tags)
        ..where((t) => t.category.equals(category))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  
  Future<void> insertTag(Tag tag) => into(tags).insert(tag);
  Future<void> updateTag(Tag tag) => update(tags).replace(tag);
  Future<void> deleteTag(String id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();
}
```

## Enum Persistence Strategy

### Problem
Using enum `index` or `name` is fragile because:
- Adding/reordering enum values changes indices
- Renaming enum values breaks existing data

### Solution: dbCode Pattern

```dart
enum TradeDirection {
  long(dbCode: 'L', displayName: '做多'),
  short(dbCode: 'S', displayName: '做空'),
  observe(dbCode: 'O', displayName: '观察');
  
  final String dbCode;
  final String displayName;
  
  const TradeDirection({
    required this.dbCode,
    required this.displayName,
  });
  
  static TradeDirection? fromDbCode(String? dbCode) {
    if (dbCode == null) return null;
    return values.firstWhere(
      (e) => e.dbCode == dbCode,
      orElse: () => observe, // Default fallback
    );
  }
}

enum TradeResult {
  profit(dbCode: 'P', displayName: '盈利'),
  loss(dbCode: 'L', displayName: '亏损'),
  observe(dbCode: 'O', displayName: '观察'),
  missed(dbCode: 'M', displayName: '错过');
  
  final String dbCode;
  final String displayName;
  
  const TradeResult({
    required this.dbCode,
    required this.displayName,
  });
  
  static TradeResult? fromDbCode(String? dbCode) {
    if (dbCode == null) return null;
    return values.firstWhere(
      (e) => e.dbCode == dbCode,
      orElse: () => observe,
    );
  }
}
```

### Usage in Entity

```dart
class Note {
  final String? direction;
  final String? result;
  
  TradeDirection? get directionEnum => TradeDirection.fromDbCode(direction);
  TradeResult? get resultEnum => TradeResult.fromDbCode(result);
  
  Note copyWith({
    TradeDirection? direction,
    TradeResult? result,
  }) {
    return Note(
      direction: direction?.dbCode ?? this.direction,
      result: result?.dbCode ?? this.result,
    );
  }
}
```

## Database Migrations

### Adding a New Column

**Step 1: Update table definition**
```dart
class Notes extends Table {
  // ... existing columns
  TextColumn get newField => text().nullable()(); // Add new column
}
```

**Step 2: Increment schema version**
```dart
@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2; // Increment from 1 to 2
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(notes, notes.newField);
        }
      },
    );
  }
}
```

**Step 3: Run code generation**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Adding a New Table

**Step 1: Define the table**
```dart
class NewTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Step 2: Add to database**
```dart
@DriftDatabase(
  tables: [Notes, Tags, SavedFilters, RecentUsages, NewTable], // Add new table
  daos: [NoteDao, TagDao, SavedFilterDao, RecentUsageDao, NewTableDao],
)
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 3; // Increment
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(notes, notes.newField);
        }
        if (from < 3) {
          await m.createTable(newTable);
        }
      },
    );
  }
}
```

### Complex Migration

For complex data transformations:

```dart
onUpgrade: (Migrator m, int from, int to) async {
  if (from < 4) {
    // Create temporary table
    await customStatement('''
      CREATE TABLE notes_temp (
        id TEXT PRIMARY KEY,
        -- new schema
      )
    ''');
    
    // Migrate data
    await customStatement('''
      INSERT INTO notes_temp
      SELECT id, ... FROM notes
    ''');
    
    // Drop old table and rename
    await customStatement('DROP TABLE notes');
    await customStatement('ALTER TABLE notes_temp RENAME TO notes');
  }
}
```

## Query Patterns

### Pagination

```dart
Future<List<Note>> getNotesPaginated(int page, int pageSize) {
  return (select(notes)
    ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
    ..limit(pageSize, offset: page * pageSize))
    .get();
}
```

### Search with LIKE

```dart
Future<List<Note>> searchNotes(String keyword) {
  return (select(notes)
    ..where((n) => n.note.like('%$keyword%'))
    ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
    .get();
}
```

### Joins (if needed)

```dart
// Get notes with their type tags
Future<List<NoteWithTag>> getNotesWithTags() async {
  final query = select(notes).join([
    leftOuterJoin(tags, tags.id.equalsExp(notes.typeTagId)),
  ]);
  
  final result = await query.get();
  return result.map((row) {
    return NoteWithTag(
      note: row.readTable(notes),
      tag: row.readTableOrNull(tags),
    );
  }).toList();
}
```

### Transactions

```dart
Future<void> deleteTagAndReassignNotes(String oldTagId, String newTagId) async {
  await transaction(() async {
    // Reassign notes
    await (update(notes)..where((n) => n.typeTagId.equals(oldTagId)))
        .write(NoteCompanion(typeTagId: Value(newTagId)));
    
    // Delete tag
    await (delete(tags)..where((t) => t.id.equals(oldTagId))).go();
  });
}
```

## Best Practices

### 1. Always Use DAOs
Don't write database queries directly in repositories. Use DAOs for:
- Type safety
- Reusability
- Testability

### 2. Keep Entities Immutable
```dart
@freezed
class Note with _$Note {
  const factory Note({
    required String id,
    required String imagePath,
    // ...
  }) = _Note;
  
  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}
```

### 3. Use Companions for Partial Updates
```dart
Future<void> updateNoteFavorite(String id, bool favorite) {
  return (update(notes)..where((n) => n.id.equals(id)))
      .write(NoteCompanion(favorite: Value(favorite)));
}
```

### 4. Test Migrations
Always test migrations with real data:
```dart
test('migration from v1 to v2', () async {
  final db = AppDatabase();
  // Insert test data with old schema
  // Verify migration works
  // Check data integrity
});
```

### 5. Backup Before Migration
For production apps, backup user data before running migrations.

## Debugging

### View Generated SQL
```dart
AppDatabase() {
  // Enable SQL logging
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
}
```

### Inspect Database
Use Drift DevTools extension or sqlite3 command line to inspect database contents.

### Common Issues

**Issue**: Generated code not updating
**Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`

**Issue**: Migration not working
**Solution**: Check `schemaVersion` is incremented and migration logic is correct

**Issue**: Type converter not applied
**Solution**: Ensure `.map(const Converter())` is used in column definition
