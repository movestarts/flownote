# Code Generation Reference

## Overview

Chart Flow uses code generation to reduce boilerplate and ensure type safety. This document explains what code is generated, how to run generation, and how to troubleshoot issues.

## What Gets Generated

### 1. Drift Database Code

**Source Files:**
- `lib/core/data/database/database.dart`
- `lib/core/data/database/tables.dart`
- `lib/core/data/dao/*.dart`

**Generated Files:**
- `lib/core/data/database/database.g.dart` - Database implementation
- `lib/core/data/dao/*.g.dart` - DAO implementations

**What's Generated:**
- SQL query builders
- Type-safe database access methods
- Companion classes for inserts/updates
- Data classes for table rows

**Example:**
```dart
// Source: tables.dart
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get imagePath => text()();
  DateTimeColumn get createdAt => dateTime()();
}

// Generated: database.g.dart
class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String imagePath;
  final DateTime createdAt;
  
  Note({
    required this.id,
    required this.imagePath,
    required this.createdAt,
  });
  
  // Generated methods: toJson, fromJson, toCompanion, etc.
}
```

### 2. Freezed Models (if used)

**Source Files:**
- `lib/core/domain/entities.dart` (if using @freezed)

**Generated Files:**
- `*.freezed.dart` - Immutable data classes
- `*.g.dart` - JSON serialization

**Example:**
```dart
// Source: entities.dart
@freezed
class NoteQuery with _$NoteQuery {
  const factory NoteQuery({
    @Default([]) List<String> typeIds,
    @Default([]) List<String> symbols,
    // ...
  }) = _NoteQuery;
  
  factory NoteQuery.fromJson(Map<String, dynamic> json) =>
      _$NoteQueryFromJson(json);
}

// Generated: *.freezed.dart
// - Immutable implementation
// - copyWith method
// - equality operators
// - toString

// Generated: *.g.dart
// - fromJson
// - toJson
```

### 3. JSON Serialization (if used)

**Generated:**
- `fromJson` constructors
- `toJson` methods

## Running Code Generation

### One-Time Generation

Run after making changes to database schema, entities, or models:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Flags Explained:**
- `build`: Run build process once
- `--delete-conflicting-outputs`: Delete old generated files before generating new ones

### Watch Mode

Automatically regenerate when files change (recommended during development):

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

**When to Use:**
- Active development on database schemas
- Frequently modifying entity classes
- Iterating on model structures

**Note:** Watch mode may consume more CPU resources. Stop it when done with active development.

### Clean and Regenerate

If generation fails or generated files are corrupted:

```bash
# Clean all generated files
flutter pub run build_runner clean

# Regenerate from scratch
flutter pub run build_runner build --delete-conflicting-outputs
```

## When to Run Code Generation

### Must Run After:

1. **Adding/Modifying Database Tables**
   ```dart
   // Added new column to Notes table
   class Notes extends Table {
     // ... existing columns
     TextColumn get newField => text().nullable()();
   }
   ```
   → Run generation

2. **Adding/Modifying DAOs**
   ```dart
   @DriftAccessor(tables: [Notes])
   class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
     // Added new query method
     Future<List<Note>> getRecentNotes() =>
       (select(notes)..limit(10)).get();
   }
   ```
   → Run generation

3. **Adding/Modifying Type Converters**
   ```dart
   class StringListConverter extends TypeConverter<List<String>, String> {
     // ... implementation
   }
   
   // Used in table
   class SavedFilters extends Table {
     TextColumn get typeIds => text().map(const StringListConverter())();
   }
   ```
   → Run generation

4. **Modifying Entity Classes with @freezed**
   ```dart
   @freezed
   class NoteQuery with _$NoteQuery {
     const factory NoteQuery({
       @Default([]) List<String> typeIds,
       String? newField, // Added new field
     }) = _NoteQuery;
   }
   ```
   → Run generation

5. **Incrementing Schema Version**
   ```dart
   @DriftDatabase(tables: [Notes])
   class AppDatabase extends _$AppDatabase {
     @override
     int get schemaVersion => 2; // Incremented
   }
   ```
   → Run generation

### Don't Need to Run After:

- Modifying UI widgets
- Updating provider logic
- Changing business logic in use cases
- Updating route definitions
- Modifying constants or themes

## Build Configuration

### build.yaml

Located at project root:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          # Apply converters to columns
          apply_converters_on_variables: true
          # Use named parameters in generated classes
          named_parameters: true
      freezed:
        enabled: true
      json_serializable:
        options:
          # Generate from/toJson methods
          any_map: false
          checked: true
```

### pubspec.yaml Dependencies

```yaml
dependencies:
  drift: ^2.14.1
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  drift_dev: ^2.14.1
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
```

## Generated File Structure

```
lib/
├── core/
│   └── data/
│       ├── database/
│       │   ├── database.dart          # Source
│       │   ├── database.g.dart        # Generated
│       │   ├── tables.dart             # Source
│       │   └── tables.g.dart           # Generated (if using freezed)
│       └── dao/
│           ├── note_dao.dart           # Source
│           └── note_dao.g.dart         # Generated
├── domain/
│   ├── entities.dart                   # Source
│   ├── entities.freezed.dart          # Generated
│   └── entities.g.dart                 # Generated
```

## Troubleshooting

### Common Error: "Builder failed"

**Cause:** Conflicting generated files from previous runs

**Solution:**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Common Error: "Part file must be generated"

**Cause:** Missing `part` directive or wrong file name

**Solution:**
```dart
// In database.dart
part 'database.g.dart';  // Must match generated file name

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  // ...
}
```

### Common Error: "Type not found"

**Cause:** Generated code not imported

**Solution:**
```dart
// Import generated file
import 'database.g.dart';

// Now can use generated classes
class MyDatabase extends _$AppDatabase {
  // ...
}
```

### Common Error: "Cannot find symbol _$AppDatabase"

**Cause:** Code generation not run yet or failed

**Solution:**
1. Check build_runner output for errors
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. Restart IDE to recognize generated files

### Common Error: "Ambiguous import"

**Cause:** Multiple generated files with same name

**Solution:**
- Use `hide` to hide conflicting imports
- Ensure unique file names across project

### Issue: Generated code outdated

**Symptoms:**
- Missing new fields in generated classes
- Methods not found
- Type mismatches

**Solution:**
```bash
# Always use --delete-conflicting-outputs
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Generated code looks wrong

**Solution:**
1. Check source file annotations
2. Verify `build.yaml` configuration
3. Check dependency versions in `pubspec.yaml`
4. Clean and regenerate:
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner clean
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## IDE Integration

### VS Code

Install recommended extensions:
- Dart
- Flutter
- build_runner (optional, for tasks)

**Task Runner:**
```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build_runner",
      "type": "shell",
      "command": "flutter pub run build_runner build --delete-conflicting-outputs",
      "problemMatcher": []
    },
    {
      "label": "build_runner watch",
      "type": "shell",
      "command": "flutter pub run build_runner watch --delete-conflicting-outputs",
      "isBackground": true,
      "problemMatcher": []
    }
  ]
}
```

### Android Studio / IntelliJ

- Generated files are recognized automatically
- Use "Pub: build_runner" action from Command Palette (Cmd+Shift+A / Ctrl+Shift+A)

## Performance Tips

### Speed Up Generation

1. **Use `--delete-conflicting-outputs`** (faster than manual deletion)
2. **Run clean periodically** to remove stale outputs
3. **Use watch mode** for active development (incremental builds)

### Reduce Generation Time

1. **Minimize generated code** (only use what's needed)
2. **Use specific imports** instead of barrel files
3. **Split large tables** into separate files

## Best Practices

### 1. Always Commit Generated Files

Generated files should be committed to version control:
- Ensures consistency across team
- Reduces build time in CI/CD
- Allows offline builds

### 2. Use Git Ignore for Generated Files?

**Don't** ignore generated files. They are part of the codebase.

### 3. Document Code Generation Requirements

In README or CONTRIBUTING, document:
- Required dependencies
- Generation commands
- When to run generation

### 4. Verify Generation in CI/CD

Add step to CI pipeline:
```yaml
# Example GitHub Action
- name: Check generated code
  run: |
    flutter pub get
    flutter pub run build_runner build --delete-conflicting-outputs
    git diff --exit-code
```

This ensures generated code is up to date before merging.

### 5. Don't Edit Generated Files

Generated files are overwritten on next run. Make changes to source files only.

## Advanced Topics

### Custom Builders

For complex use cases, create custom builders:

```yaml
# build.yaml
targets:
  $default:
    builders:
      my_package|my_builder:
        enabled: true
        options:
          custom_option: value
```

### Conditional Generation

Use `@visibleForTesting` or factory constructors to conditionally use generated code:

```dart
class NoteRepository {
  final AppDatabase db;
  
  @visibleForTesting
  NoteRepository.withDatabase(this.db);
  
  NoteRepository() : db = AppDatabase();
}
```

### Parallel Generation

build_runner uses parallelization by default. For large projects, adjust concurrency:

```bash
flutter pub run build_runner build --delete-conflicting-outputs --log-level info
```
