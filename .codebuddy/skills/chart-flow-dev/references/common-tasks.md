# Common Development Tasks

This document provides step-by-step guides for frequently performed development tasks in the Chart Flow project.

## Table of Contents

1. [Adding a New Feature Module](#adding-a-new-feature-module)
2. [Adding a New Database Field](#adding-a-new-database-field)
3. [Adding a New Tag Category](#adding-a-new-tag-category)
4. [Adding a New Filter Condition](#adding-a-new-filter-condition)
5. [Adding a New Page](#adding-a-new-page)
6. [Adding a New Service](#adding-a-new-service)
7. [Implementing Pagination](#implementing-pagination)
8. [Adding Complex Queries](#adding-complex-queries)
9. [Implementing Data Export/Import](#implementing-data-exportimport)

---

## Adding a New Feature Module

### Step-by-Step Guide

**Step 1: Create Directory Structure**

```bash
mkdir -p lib/features/my_feature/data/repositories
mkdir -p lib/features/my_feature/domain/repositories
mkdir -p lib/features/my_feature/domain/usecases
mkdir -p lib/features/my_feature/presentation/pages
mkdir -p lib/features/my_feature/presentation/widgets
mkdir -p lib/features/my_feature/providers
```

**Step 2: Define Domain Entity**

Create `lib/features/my_feature/domain/entities.dart`:

```dart
class MyEntity {
  final String id;
  final String name;
  final DateTime createdAt;
  
  MyEntity({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  
  MyEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return MyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

**Step 3: Create Repository Interface**

Create `lib/features/my_feature/domain/repositories/my_entity_repository.dart`:

```dart
abstract class MyEntityRepository {
  Future<List<MyEntity>> getAll();
  Future<MyEntity?> getById(String id);
  Future<void> create(MyEntity entity);
  Future<void> update(MyEntity entity);
  Future<void> delete(String id);
}
```

**Step 4: Define Database Table**

Add to `lib/core/data/database/tables.dart`:

```dart
class MyEntities extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Step 5: Create DAO**

Create `lib/core/data/dao/my_entity_dao.dart`:

```dart
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../tables.dart';

part 'my_entity_dao.g.dart';

@DriftAccessor(tables: [MyEntities])
class MyEntityDao extends DatabaseAccessor<AppDatabase> with _$MyEntityDaoMixin {
  MyEntityDao(AppDatabase db) : super(db);
  
  Future<List<MyEntity>> getAll() => select(myEntities).get();
  
  Future<MyEntity?> getById(String id) =>
      (select(myEntities)..where((e) => e.id.equals(id)))
          .getSingleOrNull();
  
  Future<void> insertEntity(MyEntitiesCompanion entity) =>
      into(myEntities).insert(entity);
  
  Future<void> updateEntity(MyEntitiesCompanion entity) =>
      update(myEntities).replace(entity);
  
  Future<void> deleteEntity(String id) =>
      (delete(myEntities)..where((e) => e.id.equals(id))).go();
}
```

**Step 6: Update Database Configuration**

Update `lib/core/data/database/database.dart`:

```dart
@DriftDatabase(
  tables: [Notes, Tags, SavedFilters, RecentUsages, MyEntities], // Add MyEntities
  daos: [NoteDao, TagDao, SavedFilterDao, RecentUsageDao, MyEntityDao], // Add MyEntityDao
)
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2; // Increment schema version
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertBuiltinTags();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(myEntities); // Create new table
        }
      },
    );
  }
}
```

**Step 7: Implement Repository**

Create `lib/features/my_feature/data/repositories/my_entity_repository_impl.dart`:

```dart
import '../../domain/repositories/my_entity_repository.dart';
import '../../domain/entities.dart';
import '../../../../core/data/database/database.dart';

class MyEntityRepositoryImpl implements MyEntityRepository {
  final AppDatabase db;
  
  MyEntityRepositoryImpl(this.db);
  
  @override
  Future<List<MyEntity>> getAll() async {
    final models = await db.myEntityDao.getAll();
    return models.map(_toEntity).toList();
  }
  
  @override
  Future<MyEntity?> getById(String id) async {
    final model = await db.myEntityDao.getById(id);
    return model != null ? _toEntity(model) : null;
  }
  
  @override
  Future<void> create(MyEntity entity) async {
    await db.myEntityDao.insertEntity(_toCompanion(entity));
  }
  
  @override
  Future<void> update(MyEntity entity) async {
    await db.myEntityDao.updateEntity(_toCompanion(entity));
  }
  
  @override
  Future<void> delete(String id) async {
    await db.myEntityDao.deleteEntity(id);
  }
  
  MyEntity _toEntity(MyEntity model) {
    return MyEntity(
      id: model.id,
      name: model.name,
      createdAt: model.createdAt,
    );
  }
  
  MyEntitiesCompanion _toCompanion(MyEntity entity) {
    return MyEntitiesCompanion(
      id: Value(entity.id),
      name: Value(entity.name),
      createdAt: Value(entity.createdAt),
    );
  }
}
```

**Step 8: Create Providers**

Create `lib/features/my_feature/providers/my_entity_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repositories/my_entity_repository.dart';
import '../data/repositories/my_entity_repository_impl.dart';
import '../../../shared/providers/database_provider.dart';

final myEntityRepositoryProvider = Provider<MyEntityRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return MyEntityRepositoryImpl(db);
});

final myEntitiesProvider = FutureProvider<List<MyEntity>>((ref) async {
  final repository = ref.watch(myEntityRepositoryProvider);
  return repository.getAll();
});

final myEntityProvider = FutureProvider.family<MyEntity?, String>((ref, id) async {
  final repository = ref.watch(myEntityRepositoryProvider);
  return repository.getById(id);
});
```

**Step 9: Create Page**

Create `lib/features/my_feature/presentation/pages/my_entity_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/my_entity_providers.dart';

class MyEntityPage extends ConsumerWidget {
  const MyEntityPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitiesAsync = ref.watch(myEntitiesProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Entities')),
      body: entitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (entities) => ListView.builder(
          itemCount: entities.length,
          itemBuilder: (context, index) {
            final entity = entities[index];
            return ListTile(
              title: Text(entity.name),
              subtitle: Text(entity.createdAt.toString()),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create page
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

**Step 10: Add Route**

Update `lib/app/router/app_router.dart`:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      // ... existing routes
      GoRoute(
        path: '/my-entities',
        name: 'my-entities',
        builder: (context, state) => const MyEntityPage(),
      ),
    ],
  );
});
```

**Step 11: Run Code Generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 12: Test**

```bash
flutter run
```

---

## Adding a New Database Field

### Example: Add "description" field to Notes table

**Step 1: Update Table Definition**

Edit `lib/core/data/database/tables.dart`:

```dart
class Notes extends Table {
  // ... existing fields
  TextColumn get description => text().nullable()(); // Add new field
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Step 2: Update Entity**

Edit `lib/core/domain/entities.dart`:

```dart
class Note {
  final String id;
  final String imagePath;
  // ... existing fields
  final String? description; // Add new field
  
  Note({
    required this.id,
    required this.imagePath,
    // ... existing parameters
    this.description, // Add new parameter
  });
  
  Note copyWith({
    String? id,
    String? imagePath,
    // ... existing parameters
    String? description, // Add new parameter
  }) {
    return Note(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      // ... existing fields
      description: description ?? this.description,
    );
  }
}
```

**Step 3: Increment Schema Version**

Edit `lib/core/data/database/database.dart`:

```dart
@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 3; // Increment from 2 to 3
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (Migrator m, int from, int to) async {
        // ... existing migrations
        if (from < 3) {
          await m.addColumn(notes, notes.description); // Add column
        }
      },
    );
  }
}
```

**Step 4: Update DAO (if needed)**

If you need to query by the new field, update `lib/core/data/dao/note_dao.dart`:

```dart
Future<List<Note>> searchByDescription(String keyword) {
  return (select(notes)
    ..where((n) => n.description.like('%$keyword%')))
    .get();
}
```

**Step 5: Update Repository**

Edit `lib/features/notes/data/repositories/note_repository_impl.dart`:

```dart
MyEntity _toEntity(NoteModel model) {
  return Note(
    id: model.id,
    imagePath: model.imagePath,
    // ... existing fields
    description: model.description, // Add new field mapping
  );
}

NotesCompanion _toCompanion(Note entity) {
  return NotesCompanion(
    id: Value(entity.id),
    imagePath: Value(entity.imagePath),
    // ... existing fields
    description: Value(entity.description), // Add new field
  );
}
```

**Step 6: Update UI**

Update pages to display/edit the new field:

```dart
// In create_note_page.dart
TextFormField(
  decoration: const InputDecoration(labelText: 'Description'),
  onSaved: (value) {
    _description = value;
  },
),

// When creating note
final note = Note(
  // ... existing fields
  description: _description,
);
```

**Step 7: Run Code Generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 8: Test Migration**

```bash
# Test on device with existing data
flutter run
```

---

## Adding a New Tag Category

### Example: Add "strategy" tag category

**Step 1: Update Enum**

Edit `lib/core/constants/enums.dart`:

```dart
enum TagCategory {
  type(dbCode: 'type', displayName: '类型'),
  symbol(dbCode: 'symbol', displayName: '品种'),
  timeframe(dbCode: 'timeframe', displayName: '周期'),
  result(dbCode: 'result', displayName: '结果'),
  strategy(dbCode: 'strategy', displayName: '策略'); // Add new category
  
  final String dbCode;
  final String displayName;
  
  const TagCategory({
    required this.dbCode,
    required this.displayName,
  });
  
  static TagCategory? fromDbCode(String? dbCode) {
    if (dbCode == null) return null;
    return values.firstWhere((e) => e.dbCode == dbCode);
  }
}
```

**Step 2: Add Built-in Tags (Optional)**

Edit `lib/core/data/database/database.dart`:

```dart
Future<void> _insertBuiltinTags() async {
  // ... existing tags
  
  // Add strategy tags
  await batch((b) {
    b.insertAll(tags, [
      TagsCompanion.insert(
        id: 'strategy-1',
        category: 'strategy',
        name: '突破',
        isBuiltin: const Value(true),
      ),
      TagsCompanion.insert(
        id: 'strategy-2',
        category: 'strategy',
        name: '回调',
        isBuiltin: const Value(true),
      ),
    ]);
  });
}
```

**Step 3: Update NoteQuery (if needed)**

If you want to filter by strategy, edit `lib/core/domain/entities.dart`:

```dart
class NoteQuery {
  final List<String> typeIds;
  final List<String> symbols;
  // ... existing fields
  final List<String> strategyIds; // Add new field
  
  NoteQuery({
    required this.typeIds,
    required this.symbols,
    // ... existing fields
    this.strategyIds = const [], // Add new field
  });
  
  NoteQuery copyWith({
    List<String>? typeIds,
    List<String>? symbols,
    // ... existing fields
    List<String>? strategyIds, // Add new field
  }) {
    return NoteQuery(
      typeIds: typeIds ?? this.typeIds,
      symbols: symbols ?? this.symbols,
      // ... existing fields
      strategyIds: strategyIds ?? this.strategyIds,
    );
  }
}
```

**Step 4: Update Notes Table (if needed)**

If storing strategy on notes, add field to Notes table:

```dart
class Notes extends Table {
  // ... existing fields
  TextColumn get strategyTagId => text().nullable()();
  TextColumn get strategyNameSnapshot => text().nullable()();
}
```

**Step 5: Update Filter UI**

Edit `lib/features/filters/presentation/pages/filter_page.dart`:

```dart
// Add strategy selector
if (selectedCategory == TagCategory.strategy)
  TagSelector(
    category: TagCategory.strategy,
    selectedIds: strategyIds,
    onSelectionChanged: (ids) {
      setState(() {
        strategyIds = ids;
      });
    },
  ),
```

**Step 6: Run Code Generation (if table updated)**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Adding a New Filter Condition

### Example: Add "profitAmount" filter to Notes

**Step 1: Add Field to NoteQuery**

Edit `lib/core/domain/entities.dart`:

```dart
class NoteQuery {
  // ... existing fields
  final double? minProfitAmount; // Add new field
  final double? maxProfitAmount;
  
  NoteQuery({
    // ... existing parameters
    this.minProfitAmount,
    this.maxProfitAmount,
  });
  
  NoteQuery copyWith({
    // ... existing parameters
    double? minProfitAmount,
    double? maxProfitAmount,
  }) {
    return NoteQuery(
      // ... existing fields
      minProfitAmount: minProfitAmount ?? this.minProfitAmount,
      maxProfitAmount: maxProfitAmount ?? this.maxProfitAmount,
    );
  }
}
```

**Step 2: Update SavedFilters Table**

Edit `lib/core/data/database/tables.dart`:

```dart
class SavedFilters extends Table {
  // ... existing fields
  RealColumn get minProfitAmount => real().nullable()(); // Add new field
  RealColumn get maxProfitAmount => real().nullable()();
}
```

**Step 3: Update DAO Query Logic**

Edit `lib/core/data/dao/note_dao.dart`:

```dart
Future<List<Note>> queryNotes(NoteQuery query) {
  var stmt = select(notes);
  
  // ... existing filters
  
  // Add profit amount filter
  if (query.minProfitAmount != null) {
    stmt.where((n) => n.profitAmount.isBiggerOrEqualValue(query.minProfitAmount!));
  }
  if (query.maxProfitAmount != null) {
    stmt.where((n) => n.profitAmount.isSmallerOrEqualValue(query.maxProfitAmount!));
  }
  
  return stmt.get();
}
```

**Step 4: Update Filter UI**

Edit `lib/features/filters/presentation/pages/filter_page.dart`:

```dart
// Add profit amount range selector
Row(
  children: [
    Expanded(
      child: TextFormField(
        decoration: const InputDecoration(labelText: '最小盈利'),
        keyboardType: TextInputType.number,
        onSaved: (value) {
          _minProfitAmount = double.tryParse(value ?? '');
        },
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: TextFormField(
        decoration: const InputDecoration(labelText: '最大盈利'),
        keyboardType: TextInputType.number,
        onSaved: (value) {
          _maxProfitAmount = double.tryParse(value ?? '');
        },
      ),
    ),
  ],
),
```

**Step 5: Run Code Generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Adding a New Page

### Example: Add Statistics Page

**Step 1: Create Page**

Create `lib/features/statistics/presentation/pages/statistics_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计数据'),
      ),
      body: const Center(
        child: Text('Statistics Page'),
      ),
    );
  }
}
```

**Step 2: Add Route**

Edit `lib/app/router/app_router.dart`:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      // ... existing routes
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsPage(),
      ),
    ],
  );
});
```

**Step 3: Add Navigation Entry**

Edit `lib/features/home/presentation/pages/home_page.dart`:

```dart
// Add to navigation drawer or menu
ListTile(
  leading: const Icon(Icons.bar_chart),
  title: const Text('统计数据'),
  onTap: () {
    context.goNamed('statistics');
  },
),
```

---

## Adding a New Service

### Example: Add Export Service

**Step 1: Create Service**

Create `lib/core/services/export_service.dart`:

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  Future<String> exportNotes(List<Note> notes) async {
    // Export logic
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/notes_export.json');
    
    // Write data
    await file.writeAsString(jsonEncode(notes));
    
    return file.path;
  }
  
  Future<void> shareExport(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }
}
```

**Step 2: Create Provider**

Edit `lib/shared/providers/services_provider.dart`:

```dart
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});
```

**Step 3: Use in Page**

```dart
class SettingsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () async {
          final exportService = ref.read(exportServiceProvider);
          final filePath = await exportService.exportNotes(notes);
          await exportService.shareExport(filePath);
        },
        child: const Text('导出笔记'),
      ),
    );
  }
}
```

---

## Implementing Pagination

**Step 1: Create Paginated Provider**

```dart
// lib/features/notes/providers/paginated_notes_provider.dart

final paginatedNotesProvider = StateNotifierProvider.family<
    PaginatedNotesNotifier, AsyncValue<List<Note>>, NoteQuery>(
  (ref, query) {
    final repository = ref.watch(noteRepositoryProvider);
    return PaginatedNotesNotifier(
      repository: repository,
      query: query,
    );
  },
);

class PaginatedNotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NoteRepository repository;
  final NoteQuery query;
  int _page = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  
  PaginatedNotesNotifier({
    required this.repository,
    required this.query,
  }) : super(const AsyncLoading()) {
    _loadMore();
  }
  
  Future<void> loadMore() async {
    if (!_hasMore) return;
    await _loadMore();
  }
  
  Future<void> refresh() async {
    _page = 0;
    _hasMore = true;
    state = const AsyncLoading();
    await _loadMore();
  }
  
  Future<void> _loadMore() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final newNotes = await repository.queryNotes(
        query.copyWith(
          offset: _page * _pageSize,
          limit: _pageSize,
        ),
      );
      
      _hasMore = newNotes.length == _pageSize;
      _page++;
      
      final currentNotes = state.valueOrNull ?? [];
      return [...currentNotes, ...newNotes];
    });
  }
}
```

**Step 2: Use in Page**

```dart
class FlowPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends ConsumerState<FlowPage> {
  late final ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedNotesProvider(query).notifier).loadMore();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(paginatedNotesProvider(query));
    
    return Scaffold(
      body: notesAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) => Text('Error: $err'),
        data: (notes) => ListView.builder(
          controller: _scrollController,
          itemCount: notes.length + 1,
          itemBuilder: (context, index) {
            if (index == notes.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return NoteCard(note: notes[index]);
          },
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

---

## Adding Complex Queries

**Example: Get notes grouped by month**

**Step 1: Add DAO Method**

```dart
// lib/core/data/dao/note_dao.dart

Future<Map<String, List<Note>>> getNotesGroupedByMonth() async {
  final notes = await select(notes).get();
  
  final grouped = <String, List<Note>>{};
  for (final note in notes) {
    final monthKey = '${note.createdAt.year}-${note.createdAt.month.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(monthKey, () => []).add(note);
  }
  
  return grouped;
}
```

**Step 2: Use in Repository**

```dart
// lib/features/notes/data/repositories/note_repository_impl.dart

Future<Map<String, List<Note>>> getNotesGroupedByMonth() async {
  final grouped = await db.noteDao.getNotesGroupedByMonth();
  return grouped.map((key, notes) => MapEntry(
    key,
    notes.map(_toEntity).toList(),
  ));
}
```

**Step 3: Create Provider**

```dart
// lib/features/notes/providers/note_providers.dart

final notesGroupedByMonthProvider = FutureProvider<Map<String, List<Note>>>((ref) async {
  final repository = ref.watch(noteRepositoryProvider);
  return repository.getNotesGroupedByMonth();
});
```

---

## Implementing Data Export/Import

**Step 1: Create Export Service**

```dart
// lib/core/services/data_export_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DataExportService {
  final AppDatabase db;
  
  DataExportService(this.db);
  
  Future<String> exportAllData() async {
    final notes = await db.noteDao.getAllNotes();
    final tags = await db.tagDao.getAllTags();
    final filters = await db.savedFilterDao.getAllFilters();
    
    final exportData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'notes': notes.map((n) => _noteToMap(n)).toList(),
      'tags': tags.map((t) => _tagToMap(t)).toList(),
      'filters': filters.map((f) => _filterToMap(f)).toList(),
    };
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/chart_flow_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonEncode(exportData));
    
    return file.path;
  }
  
  Future<void> importData(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    
    // Validate version
    final version = data['version'] as int;
    if (version != 1) {
      throw Exception('Unsupported backup version: $version');
    }
    
    // Import tags first (notes reference tags)
    for (final tagMap in data['tags'] as List) {
      await db.tagDao.insertTag(_mapToTag(tagMap));
    }
    
    // Import notes
    for (final noteMap in data['notes'] as List) {
      await db.noteDao.insertNote(_mapToNote(noteMap));
    }
    
    // Import filters
    for (final filterMap in data['filters'] as List) {
      await db.savedFilterDao.insertFilter(_mapToFilter(filterMap));
    }
  }
  
  Map<String, dynamic> _noteToMap(Note note) {
    return {
      'id': note.id,
      'imagePath': note.imagePath,
      // ... all fields
    };
  }
  
  // ... other conversion methods
}
```

**Step 2: Create Provider**

```dart
// lib/shared/providers/services_provider.dart

final dataExportServiceProvider = Provider<DataExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return DataExportService(db);
});
```

**Step 3: Use in Settings Page**

```dart
// lib/features/settings/presentation/pages/settings_page.dart

class SettingsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('导出数据'),
            onTap: () async {
              final exportService = ref.read(dataExportServiceProvider);
              final path = await exportService.exportAllData();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('数据已导出到: $path')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入数据'),
            onTap: () async {
              // Use file_picker to select file
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
              );
              
              if (result != null) {
                final file = result.files.single;
                if (file.path != null) {
                  final exportService = ref.read(dataExportServiceProvider);
                  await exportService.importData(file.path!);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('数据导入成功')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
```

---

## Summary

Each task follows these general principles:

1. **Domain First**: Start with domain layer (entities, repositories)
2. **Data Second**: Implement data layer (database, DAOs, repository implementations)
3. **Wire with Providers**: Use Riverpod to connect layers
4. **UI Last**: Build presentation layer
5. **Code Generation**: Run after database changes
6. **Test**: Verify functionality

Always run code generation after:
- Adding/modifying database tables
- Adding/modifying DAOs
- Adding/modifying type converters
- Modifying entities with annotations
