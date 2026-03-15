---
name: chart-flow-dev
description: This skill should be used when developing the Chart Flow (图流复盘) Flutter application - a trading review app with image-first approach. Use when adding features, modifying database schemas, implementing new pages, or understanding the project architecture.
---

# Chart Flow Development Skill

## Purpose

Provide specialized knowledge and workflows for developing the Chart Flow application - a Flutter-based trading review app that uses an image-first approach to help traders record, categorize, and review trading cases.

## When to Use

Use this skill when:
- Adding new features or modifying existing ones in the Chart Flow project
- Understanding the project architecture and design patterns
- Modifying database schemas or adding new tables
- Implementing new pages or navigation routes
- Adding new tag categories or filter conditions
- Working with Riverpod state management
- Generating database code with build_runner
- Implementing services or repositories
- Understanding the domain-driven design structure

## Project Overview

Chart Flow is a Flutter application for trading review with these core features:
- **Image-first approach**: Trading chart screenshots as the primary content
- **Flow-style browsing**: Vertical swipe navigation similar to short videos
- **Smart tagging**: Multi-dimensional tags (type, symbol, timeframe, direction, result)
- **Flexible filtering**: Combine multiple conditions to quickly locate target notes
- **Local storage**: All data stored locally for privacy protection

## Key Architecture Patterns

### Layered Architecture (Feature-First)

The project follows a clean architecture with feature-first organization:

```
lib/
├── app/           # Application layer (routing, theme)
├── core/          # Core layer (database, services, widgets)
├── features/      # Feature modules
│   ├── notes/     # Notes feature
│   ├── tags/      # Tags feature
│   ├── filters/   # Filters feature
│   └── settings/  # Settings feature
└── shared/        # Shared across features
```

Each feature module follows the same structure:
```
feature/
├── data/           # Data layer (repositories implementation)
├── domain/         # Domain layer (entities, repositories, usecases)
├── presentation/   # Presentation layer (pages, widgets)
└── providers/      # Riverpod providers
```

### State Management with Riverpod

The project uses Riverpod for state management with these patterns:
- **Repository Provider**: Single source of truth for data access
- **Async Data Provider**: For asynchronous data fetching with automatic refresh
- **StateNotifier Provider**: For complex state with pagination
- **Refresh Tick Pattern**: Simple counter to trigger data refresh

### Database with Drift

Drift (SQLite) is used for local persistence:
- Type-safe database queries
- DAOs for each table
- Type converters for complex types (List<String>, enums)
- Enum persistence via `dbCode` field

### Routing with go_router

Declarative routing using go_router:
- Path parameters for simple data (note IDs)
- Extra parameter for complex objects (NoteQuery)
- Named routes for easy navigation

## Common Development Tasks

### Adding a New Feature Module

1. Create feature directory structure under `lib/features/`
2. Define domain entities in `domain/entities.dart`
3. Create repository interface in `domain/repositories/`
4. Implement database table in `core/data/database/tables.dart`
5. Create DAO in `core/data/dao/`
6. Implement repository in `data/repositories/`
7. Create Riverpod providers in `providers/`
8. Build UI pages in `presentation/pages/`
9. Add routes in `app/router/app_router.dart`
10. Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`

### Modifying Database Schema

1. Update table definition in `lib/core/data/database/tables.dart`
2. Increment `schemaVersion` in `database.dart`
3. Add migration in `onUpgrade` method
4. Update corresponding DAO if needed
5. Update entity class in `domain/entities.dart`
6. Update repository implementation
7. Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`

For detailed steps, see `references/database.md`.

### Adding a New Tag Category

1. Add enum value in `core/constants/enums.dart` with `dbCode` and `displayName`
2. Add built-in tags in database initialization (optional)
3. Update UI components (tag selector, filter page)
4. Update `NoteQuery` if needed for filtering

### Adding a New Filter Condition

1. Add field to `NoteQuery` class in `core/domain/entities.dart`
2. Update `SavedFilters` table definition
3. Update `SavedFilter` entity
4. Update DAO query logic
5. Update filter page UI
6. Run code generation

## Code Generation

The project uses code generation for:
- Drift database code (`database.g.dart`, `*.g.dart` for DAOs)
- Freezed models (if any)
- JSON serialization

**Commands:**
```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous development
flutter pub run build_runner watch --delete-conflicting-outputs
```

Always run code generation after modifying:
- Database table definitions
- DAO queries
- Entity classes with Freezed annotations

## Key Files to Reference

- **Architecture**: `references/architecture.md` - Detailed architecture explanation
- **Database**: `references/database.md` - Database schema and migration guide
- **Code Generation**: `references/code-generation.md` - Detailed code generation workflow
- **Common Tasks**: `references/common-tasks.md` - Step-by-step guides for frequent tasks

## Important Conventions

### Enum Persistence

Always use `dbCode` for enum persistence, not `index` or `name`:
```dart
enum TradeDirection {
  long(dbCode: 'L', displayName: '做多'),
  short(dbCode: 'S', displayName: '做空'),
  observe(dbCode: 'O', displayName: '观察');
  
  final String dbCode;
  final String displayName;
  
  static TradeDirection? fromDbCode(String? dbCode) {
    if (dbCode == null) return null;
    return values.firstWhere((e) => e.dbCode == dbCode);
  }
}
```

### Type Converters

Use Drift TypeConverter for complex types:
```dart
class StringListConverter extends TypeConverter<List<String>, String> {
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

### Refresh Pattern

Use refresh tick for triggering data refresh:
```dart
final notesRefreshTickProvider = StateProvider<int>((ref) => 0);

// In provider
ref.watch(notesRefreshTickProvider);

// Trigger refresh
ref.read(notesRefreshTickProvider.notifier).state++;
```

### File Naming

- Files: `snake_case.dart` (e.g., `note_repository.dart`)
- Classes: `PascalCase` (e.g., `NoteRepository`)
- Variables/Functions: `camelCase` (e.g., `getNoteById`)
- Constants: `PascalCase` (e.g., `AppConstants`)

## Debugging Tips

### Database Issues

- Check generated code in `*.g.dart` files
- Verify migration logic in `database.dart`
- Use Drift inspector for debugging (if configured)

### State Management Issues

- Check provider dependencies with `ref.watch` vs `ref.read`
- Verify refresh tick is being watched
- Use `AsyncValue` for proper loading/error states

### Routing Issues

- Check path parameters match route definition
- Verify `extra` parameter type matches expectation
- Use named routes for type safety

## Testing

Run tests with:
```bash
flutter test
```

Database tests should use in-memory SQLite for isolation.

## Build & Deploy

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Windows
```bash
flutter build windows --release
```
