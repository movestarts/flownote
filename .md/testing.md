# 测试说明

## 测试策略

本项目采用分层测试策略，确保各层级的正确性和稳定性。

```
┌─────────────────────────────────────────────────────┐
│                   Widget Tests                       │
│              (UI 组件测试)                           │
├─────────────────────────────────────────────────────┤
│                   Unit Tests                         │
│        (Repository, Service, UseCase 测试)           │
├─────────────────────────────────────────────────────┤
│                Integration Tests                     │
│           (DAO, Database 测试)                       │
└─────────────────────────────────────────────────────┘
```

## 测试目录结构

```
test/
├── core/
│   ├── data/
│   │   └── dao/
│   │       ├── note_dao_test.dart
│   │       ├── tag_dao_test.dart
│   │       └── saved_filter_dao_test.dart
│   ├── services/
│   │   ├── local_file_service_test.dart
│   │   └── cleanup_service_test.dart
│   └── converters/
│       └── string_list_converter_test.dart
├── features/
│   ├── notes/
│   │   ├── data/
│   │   │   └── note_repository_test.dart
│   │   └── domain/
│   │       └── create_note_usecase_test.dart
│   ├── tags/
│   │   └── data/
│   │       └── tag_repository_test.dart
│   └── filters/
│       └── data/
│           └── saved_filter_repository_test.dart
├── widgets/
│   ├── empty_state_widget_test.dart
│   └── image_picker_card_test.dart
└── test_utils/
    ├── mock_database.dart
    ├── mock_repositories.dart
    └── test_fixtures.dart
```

## 测试工具

### 依赖

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0          # Mock 框架
  drift_dev: ^2.14.1        # Drift 测试支持
  build_runner: ^2.4.7      # 代码生成
```

### 测试数据库配置

```dart
// test/test_utils/mock_database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
```

## 单元测试示例

### 1. DAO 测试

```dart
// test/core/data/dao/note_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chart_flow/core/data/database/database.dart';
import 'package:chart_flow/core/data/dao/note_dao.dart';
import 'package:chart_flow/core/domain/entities.dart';
import '../../test_utils/mock_database.dart';

void main() {
  late AppDatabase db;
  late NoteDao noteDao;

  setUp(() async {
    db = createTestDatabase();
    await db.initialize();
    noteDao = NoteDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('NoteDao', () {
    test('createNoteEntry should insert note into database', () async {
      final note = Note(
        id: 'test-1',
        imagePath: '/path/to/image.jpg',
        typeTagId: 'type-1',
        typeNameSnapshot: '突破',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await noteDao.createNoteEntry(note);

      final retrieved = await noteDao.getNoteById('test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test-1'));
      expect(retrieved.typeNameSnapshot, equals('突破'));
    });

    test('queryNotes should filter by typeIds', () async {
      // 准备测试数据
      await noteDao.createNoteEntry(Note(
        id: 'note-1',
        imagePath: '/path/1.jpg',
        typeTagId: 'type-A',
        typeNameSnapshot: 'Type A',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await noteDao.createNoteEntry(Note(
        id: 'note-2',
        imagePath: '/path/2.jpg',
        typeTagId: 'type-B',
        typeNameSnapshot: 'Type B',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final query = NoteQuery(typeIds: ['type-A']);
      final results = await noteDao.queryNotes(query);

      expect(results.length, equals(1));
      expect(results.first.typeTagId, equals('type-A'));
    });

    test('toggleFavorite should toggle favorite status', () async {
      await noteDao.createNoteEntry(Note(
        id: 'note-1',
        imagePath: '/path/1.jpg',
        typeTagId: 'type-1',
        typeNameSnapshot: 'Test',
        favorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await noteDao.toggleFavorite('note-1');
      var note = await noteDao.getNoteById('note-1');
      expect(note!.favorite, isTrue);

      await noteDao.toggleFavorite('note-1');
      note = await noteDao.getNoteById('note-1');
      expect(note!.favorite, isFalse);
    });
  });
}
```

### 2. Repository 测试

```dart
// test/features/notes/data/note_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chart_flow/features/notes/domain/repositories/note_repository.dart';
import 'package:chart_flow/features/notes/data/repositories/note_repository_impl.dart';
import '../../test_utils/mock_database.dart';

class MockNoteDao extends Mock implements NoteDao {}

void main() {
  late NoteRepository repository;
  late MockNoteDao mockDao;

  setUp(() {
    mockDao = MockNoteDao();
    repository = NoteRepositoryImpl(mockDao);
  });

  group('NoteRepository', () {
    test('getNoteById returns note from DAO', () async {
      final note = Note(
        id: 'test-1',
        imagePath: '/path.jpg',
        typeTagId: 'type-1',
        typeNameSnapshot: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockDao.getNoteById('test-1'))
          .thenAnswer((_) async => note);

      final result = await repository.getNoteById('test-1');

      expect(result, equals(note));
      verify(() => mockDao.getNoteById('test-1')).called(1);
    });

    test('createNote calls DAO createNoteEntry', () async {
      final note = Note(
        id: 'test-1',
        imagePath: '/path.jpg',
        typeTagId: 'type-1',
        typeNameSnapshot: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockDao.createNoteEntry(note))
          .thenAnswer((_) async {});

      await repository.createNote(note);

      verify(() => mockDao.createNoteEntry(note)).called(1);
    });
  });
}
```

### 3. UseCase 测试

```dart
// test/features/notes/domain/create_note_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chart_flow/features/notes/domain/usecases/create_note_usecase.dart';
import 'package:chart_flow/features/notes/domain/repositories/note_repository.dart';
import 'package:chart_flow/core/services/local_file_service.dart';

class MockNoteRepository extends Mock implements NoteRepository {}
class MockLocalFileService extends Mock implements LocalFileService {}

void main() {
  late CreateNoteUseCase useCase;
  late MockNoteRepository mockRepository;
  late MockLocalFileService mockFileService;

  setUp(() {
    mockRepository = MockNoteRepository();
    mockFileService = MockLocalFileService();
    useCase = CreateNoteUseCase(
      noteRepository: mockRepository,
      fileService: mockFileService,
    );
  });

  group('CreateNoteUseCase', () {
    test('execute copies image and creates note', () async {
      when(() => mockFileService.copyImageToAppDirectory('/source/path.jpg'))
          .thenAnswer((_) async => '/app/path/image.jpg');
      when(() => mockRepository.createNote(any()))
          .thenAnswer((_) async {});

      final result = await useCase.execute(
        sourceImagePath: '/source/path.jpg',
        typeTagId: 'type-1',
        typeNameSnapshot: '突破',
      );

      expect(result.imagePath, equals('/app/path/image.jpg'));
      expect(result.typeTagId, equals('type-1'));
      verify(() => mockFileService.copyImageToAppDirectory('/source/path.jpg')).called(1);
      verify(() => mockRepository.createNote(any())).called(1);
    });
  });
}
```

### 4. Service 测试

```dart
// test/core/services/local_file_service_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chart_flow/core/services/local_file_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late LocalFileService service;
  late Directory tempDir;

  setUp(() async {
    service = LocalFileService();
    tempDir = await Directory.systemTemp.createTemp('test_images_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalFileService', () {
    test('copyImageToAppDirectory creates copy with unique name', () async {
      final sourceFile = File(p.join(tempDir.path, 'source.jpg'));
      await sourceFile.writeAsString('test image content');

      final destPath = await service.copyImageToAppDirectory(sourceFile.path);

      expect(await File(destPath).exists(), isTrue);
      expect(p.extension(destPath), equals('.jpg'));
      expect(destPath, isNot(equals(sourceFile.path)));
    });

    test('copyImageToAppDirectory throws for non-existent file', () async {
      expect(
        () => service.copyImageToAppDirectory('/non/existent/path.jpg'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('deleteImage removes file', () async {
      final file = File(p.join(tempDir.path, 'to_delete.jpg'));
      await file.writeAsString('content');
      expect(await file.exists(), isTrue);

      await service.deleteImage(file.path);

      expect(await file.exists(), isFalse);
    });
  });
}
```

### 5. Converter 测试

```dart
// test/core/converters/string_list_converter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chart_flow/core/data/converters/string_list_converter.dart';

void main() {
  late StringListConverter converter;

  setUp(() {
    converter = const StringListConverter();
  });

  group('StringListConverter', () {
    test('toSql converts list to JSON string', () {
      final list = ['a', 'b', 'c'];
      final result = converter.toSql(list);
      expect(result, equals('["a","b","c"]'));
    });

    test('toSql returns empty array for empty list', () {
      final result = converter.toSql([]);
      expect(result, equals('[]'));
    });

    test('fromSql parses JSON string to list', () {
      final result = converter.fromSql('["x","y","z"]');
      expect(result, equals(['x', 'y', 'z']));
    });

    test('fromSql returns empty list for empty string', () {
      final result = converter.fromSql('');
      expect(result, isEmpty);
    });

    test('fromSql handles invalid JSON gracefully', () {
      final result = converter.fromSql('not valid json');
      expect(result, isEmpty);
    });
  });
}
```

## Widget 测试示例

```dart
// test/widgets/empty_state_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chart_flow/core/widgets/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'No Data',
              subtitle: 'Tap to add',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Tap to add'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              action: TextButton(
                onPressed: () => pressed = true,
                child: const Text('Add'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add'));
      expect(pressed, isTrue);
    });
  });
}
```

## 集成测试示例

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chart_flow/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('create note flow', (tester) async {
      await app.main();

      // 等待首页加载
      await tester.pumpAndSettle();

      // 点击创建按钮
      await tester.tap(find.byIcon(Icons.add_photo_alternate));
      await tester.pumpAndSettle();

      // 验证进入创建页面
      expect(find.text('Create Note'), findsOneWidget);
    });
  });
}
```

## 运行测试

### 运行所有测试

```bash
flutter test
```

### 运行特定测试文件

```bash
flutter test test/core/data/dao/note_dao_test.dart
```

### 运行带覆盖率的测试

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 运行集成测试

```bash
flutter test integration_test/app_test.dart
```

## 测试最佳实践

### 1. 测试命名

```dart
// 好的命名
test('getNoteById returns null for non-existent id', () async {
  // ...
});

// 不好的命名
test('test1', () async {
  // ...
});
```

### 2. 测试结构 (AAA 模式)

```dart
test('description', () async {
  // Arrange - 准备
  final note = Note(...);
  
  // Act - 执行
  await repository.createNote(note);
  
  // Assert - 断言
  final result = await repository.getNoteById(note.id);
  expect(result, isNotNull);
});
```

### 3. 使用 Fixtures

```dart
// test/test_utils/test_fixtures.dart
class TestFixtures {
  static Note createNote({
    String id = 'test-note',
    String typeTagId = 'type-1',
    String typeNameSnapshot = 'Test Type',
  }) {
    return Note(
      id: id,
      imagePath: '/test/path.jpg',
      typeTagId: typeTagId,
      typeNameSnapshot: typeNameSnapshot,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  static Tag createTag({
    String id = 'test-tag',
    TagCategory category = TagCategory.type,
    String name = 'Test Tag',
  }) {
    return Tag(
      id: id,
      category: category,
      name: name,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }
}
```

### 4. 测试边界条件

```dart
group('NoteQuery', () {
  test('isEmpty returns true for empty query', () {
    expect(const NoteQuery().isEmpty, isTrue);
  });

  test('isEmpty returns false when typeIds is not empty', () {
    expect(const NoteQuery(typeIds: ['a']).isEmpty, isFalse);
  });

  test('isEmpty returns false when favoriteOnly is set', () {
    expect(const NoteQuery(favoriteOnly: true).isEmpty, isFalse);
  });
});
```

## 测试覆盖率目标

| 层级 | 目标覆盖率 |
|------|-----------|
| Domain Entities | 100% |
| Repository Interfaces | N/A |
| Repository Implementations | 80%+ |
| DAOs | 90%+ |
| Services | 90%+ |
| UseCases | 90%+ |
| Widgets | 70%+ |

## 持续集成

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter pub run build_runner build --delete-conflicting-outputs
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
```
