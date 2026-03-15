# Architecture Reference

## Overview

Chart Flow follows Clean Architecture principles with a feature-first organization. This document provides detailed explanation of the architectural layers and patterns used in the project.

## Layered Structure

### 1. Application Layer (`lib/app/`)

The outermost layer containing application-wide configuration:

```
app/
├── app.dart              # Main application widget
├── router/
│   └── app_router.dart   # go_router configuration
└── theme/
    └── app_theme.dart    # Light/dark theme definitions
```

**Responsibilities:**
- Application initialization
- Theme configuration
- Route definitions
- Global providers setup

**Key Pattern:**
```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(themeProvider);
    
    return MaterialApp.router(
      routerConfig: router,
      theme: theme,
    );
  }
}
```

### 2. Core Layer (`lib/core/`)

Contains shared infrastructure and utilities:

```
core/
├── constants/            # Application-wide constants
│   ├── app_constants.dart
│   └── enums.dart
├── data/                 # Core data layer
│   ├── converters/       # Drift type converters
│   ├── database/         # Database definitions
│   └── dao/              # Data access objects
├── domain/              # Core domain entities
├── errors/              # Custom exceptions
├── services/            # Infrastructure services
└── widgets/             # Shared widgets
```

**Responsibilities:**
- Database configuration and migrations
- Data access layer (DAOs)
- File management services
- Shared widgets and utilities
- Custom exception definitions

**Why core/ vs shared/?**
- `core/` contains infrastructure that is truly cross-cutting
- `shared/` contains code that is shared between features but not infrastructure

### 3. Features Layer (`lib/features/`)

Feature modules following domain-driven design:

```
features/
├── notes/                # Notes feature
│   ├── data/
│   │   └── repositories/
│   │       └── note_repository_impl.dart
│   ├── domain/
│   │   ├── entities.dart
│   │   ├── repositories/
│   │   │   └── note_repository.dart
│   │   └── usecases/
│   │       ├── create_note_usecase.dart
│   │       └── query_notes_usecase.dart
│   ├── presentation/
│   │   └── pages/
│   │       ├── create_note_page.dart
│   │       ├── edit_note_page.dart
│   │       └── flow_page.dart
│   └── providers/
│       ├── note_providers.dart
│       └── paginated_notes_provider.dart
├── tags/                 # Tags feature
├── filters/              # Filters feature
└── settings/             # Settings feature
```

**Each feature contains:**

#### Data Layer (`data/`)
- Repository implementations
- Data source coordination
- Data transformations

#### Domain Layer (`domain/`)
- **Entities**: Core business objects (Note, Tag, SavedFilter, NoteQuery)
- **Repository Interfaces**: Contracts for data access
- **Use Cases**: Single-responsibility business logic

#### Presentation Layer (`presentation/`)
- Pages: Full-screen widgets
- Widgets: Reusable UI components
- State management integration

#### Providers Layer (`providers/`)
- Riverpod provider definitions
- State management logic
- Dependency injection

### 4. Shared Layer (`lib/shared/`)

Code shared between features:

```
shared/
├── data/
│   └── repositories/
│       └── recent_usage_repository_impl.dart
├── domain/
│   └── repositories/
│       └── recent_usage_repository.dart
└── providers/
    ├── database_provider.dart
    ├── recent_usage_providers.dart
    └── services_provider.dart
```

**Shared vs Core:**
- **Shared**: Business logic shared between features (e.g., RecentUsage tracking)
- **Core**: Infrastructure and utilities (e.g., database, file services)

## Dependency Flow

```
Presentation → Domain ← Data
     ↓           ↓       ↓
  Providers   Entities  Repositories
                    ↓
                  Database/Services
```

**Rules:**
1. Domain layer has NO dependencies on outer layers
2. Data layer depends on Domain (implements interfaces)
3. Presentation layer depends on Domain (through providers)
4. Providers wire everything together

## Key Patterns

### Repository Pattern

**Interface (Domain):**
```dart
abstract class NoteRepository {
  Future<List<Note>> queryNotes(NoteQuery query);
  Future<Note> getNoteById(String id);
  Future<void> createNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String id);
}
```

**Implementation (Data):**
```dart
class NoteRepositoryImpl implements NoteRepository {
  final AppDatabase db;
  
  NoteRepositoryImpl(this.db);
  
  @override
  Future<List<Note>> queryNotes(NoteQuery query) async {
    // Use DAO to fetch data
    final notes = await db.noteDao.queryNotes(query);
    // Transform database models to domain entities
    return notes.map(_toEntity).toList();
  }
}
```

### Use Case Pattern

Single-responsibility business logic:

```dart
class CreateNoteUseCase {
  final NoteRepository _noteRepository;
  final LocalFileService _fileService;
  
  CreateNoteUseCase(this._noteRepository, this._fileService);
  
  Future<Note> call({
    required String imagePath,
    required String typeTagId,
    // ... other params
  }) async {
    // 1. Copy image to app directory
    final savedPath = await _fileService.copyImageToAppDirectory(imagePath);
    
    // 2. Create note entity
    final note = Note(
      id: uuid.v4(),
      imagePath: savedPath,
      typeTagId: typeTagId,
      createdAt: DateTime.now(),
    );
    
    // 3. Persist to database
    await _noteRepository.createNote(note);
    
    return note;
  }
}
```

### Dependency Injection with Riverpod

**Repository Provider:**
```dart
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NoteRepositoryImpl(db);
});
```

**Use Case Provider:**
```dart
final createNoteUseCaseProvider = Provider<CreateNoteUseCase>((ref) {
  final noteRepo = ref.watch(noteRepositoryProvider);
  final fileService = ref.watch(localFileServiceProvider);
  return CreateNoteUseCase(noteRepo, fileService);
});
```

**Page Provider:**
```dart
final notesByQueryProvider = FutureProvider.family<List<Note>, NoteQuery>(
  (ref, query) async {
    ref.watch(notesRefreshTickProvider); // Watch for refresh
    final repository = ref.watch(noteRepositoryProvider);
    return repository.queryNotes(query);
  },
);
```

## State Management Patterns

### Async Value Pattern

Handle loading, data, and error states:

```dart
class FlowPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesByQueryProvider(query));
    
    return notesAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
      data: (notes) => NotesList(notes: notes),
    );
  }
}
```

### Pagination Pattern

For large datasets:

```dart
final paginatedNotesProvider = StateNotifierProvider.family<
    PaginatedNotesNotifier, AsyncValue<List<Note>>, NoteQuery>(
  (ref, query) {
    final repository = ref.watch(noteRepositoryProvider);
    return PaginatedNotesNotifier(repository: repository, query: query);
  },
);

class PaginatedNotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NoteRepository repository;
  final NoteQuery query;
  int _page = 0;
  final int _pageSize = 20;
  
  PaginatedNotesNotifier({
    required this.repository,
    required this.query,
  }) : super(const AsyncLoading()) {
    _loadMore();
  }
  
  Future<void> _loadMore() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final notes = await repository.queryNotes(
        query.copyWith(
          offset: _page * _pageSize,
          limit: _pageSize,
        ),
      );
      _page++;
      return [...state.value ?? [], ...notes];
    });
  }
}
```

### Refresh Pattern

Simple counter to trigger refresh:

```dart
// Define tick provider
final notesRefreshTickProvider = StateProvider<int>((ref) => 0);

// Watch in data provider
final notesProvider = FutureProvider.family<List<Note>, NoteQuery>(
  (ref, query) async {
    ref.watch(notesRefreshTickProvider); // Watch tick
    final repository = ref.watch(noteRepositoryProvider);
    return repository.queryNotes(query);
  },
);

// Trigger refresh
ref.read(notesRefreshTickProvider.notifier).state++;
```

## Routing Architecture

### Route Definition

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/note/:id/edit',
        name: 'edit',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EditNotePage(noteId: id);
        },
      ),
      GoRoute(
        path: '/flow',
        name: 'flow',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is NoteQuery) {
            return FlowPage(query: extra);
          }
          return const FlowPage();
        },
      ),
    ],
  );
});
```

### Navigation Patterns

**Simple parameter:**
```dart
context.push('/note/$noteId/edit');
```

**Complex object:**
```dart
context.push('/flow', extra: NoteQuery(
  typeIds: ['type-1'],
  favoriteOnly: true,
));
```

**Named route:**
```dart
context.goNamed('edit', pathParameters: {'id': noteId});
```

## Error Handling

### Custom Exceptions

```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, {this.code});
  
  @override
  String toString() => message;
}

class TagInUseException extends AppException {
  final String tagId;
  final int noteCount;
  
  TagInUseException({
    required this.tagId,
    required this.noteCount,
  }) : super(
    '标签正在被 $noteCount 条笔记使用,无法删除',
    code: 'TAG_IN_USE',
  );
}
```

### Exception Handling in Repository

```dart
Future<void> deleteTag(String tagId) async {
  // Check if tag is in use
  final noteCount = await db.noteDao.countByTypeTag(tagId);
  if (noteCount > 0) {
    throw TagInUseException(tagId: tagId, noteCount: noteCount);
  }
  
  // Safe to delete
  await db.tagDao.deleteTag(tagId);
}
```

### UI Error Handling

```dart
try {
  await ref.read(deleteTagProvider(tagId).future);
  Navigator.pop(context);
} on TagInUseException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('删除失败: $e')),
  );
}
```

## Testing Strategy

### Unit Tests
- Test repositories with mock DAOs
- Test use cases with mock repositories
- Test providers with ProviderScope

### Integration Tests
- Test database migrations
- Test complete workflows

### Widget Tests
- Test individual pages
- Test navigation flows

## Performance Considerations

### Database Queries
- Use indexes on frequently queried fields
- Implement pagination for large datasets
- Use `watch` for reactive queries when needed

### Image Handling
- Compress images before saving
- Implement lazy loading for images
- Clean up orphaned images periodically

### State Management
- Use `ref.watch` for reactive dependencies
- Use `ref.read` for event handlers
- Avoid rebuilding unnecessary widgets
