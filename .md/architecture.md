# 架构说明

## 整体架构

本项目采用 **Feature-First** 的分层架构，结合 Clean Architecture 的核心思想，确保代码的可维护性和可测试性。

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  (Pages, Widgets, Providers)                                 │
├─────────────────────────────────────────────────────────────┤
│                      Domain Layer                            │
│  (Entities, Repository Interfaces, UseCases)                 │
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                              │
│  (Repository Implementations, DAOs, Database, Services)      │
└─────────────────────────────────────────────────────────────┘
```

## 目录结构详解

### 1. App 层 (`lib/app/`)

应用入口和全局配置。

```
app/
├── app.dart              # MaterialApp 配置
├── router/
│   └── app_router.dart   # go_router 路由配置
└── theme/
    └── app_theme.dart    # 明暗主题配置
```

**职责**:
- 应用初始化
- 路由管理
- 主题配置

### 2. Core 层 (`lib/core/`)

跨功能模块的共享基础设施。

```
core/
├── constants/
│   ├── app_constants.dart  # 应用常量
│   └── enums.dart          # 枚举定义 (含 dbCode)
├── data/
│   ├── converters/
│   │   └── string_list_converter.dart  # List<String> 类型转换器
│   ├── database/
│   │   ├── database.dart   # Drift 数据库定义
│   │   ├── database.g.dart # 生成的数据库代码
│   │   └── tables.dart     # 表定义
│   └── dao/                # 数据访问对象
├── domain/
│   └── entities.dart       # 领域实体
├── errors/
│   └── exceptions.dart     # 自定义异常
├── services/
│   ├── cleanup_service.dart     # 孤立文件清理
│   └── local_file_service.dart  # 本地文件管理
└── widgets/
    ├── empty_state_widget.dart  # 空状态组件
    ├── image_picker_card.dart   # 图片选择卡片
    └── tag_selector.dart        # 标签选择器
```

### 3. Features 层 (`lib/features/`)

按功能划分的业务模块。

每个功能模块遵循以下结构：

```
features/{feature}/
├── data/
│   └── repositories/
│       └── {feature}_repository_impl.dart  # Repository 实现
├── domain/
│   ├── repositories/
│   │   └── {feature}_repository.dart       # Repository 接口
│   └── usecases/                           # 用例 (可选)
├── presentation/
│   └── pages/
│       └── {feature}_page.dart             # 页面
└── providers/
    └── {feature}_providers.dart            # Riverpod Providers
```

#### Notes 模块

核心笔记功能。

**实体**: `Note`, `NoteQuery`

**Repository 接口**: `NoteRepository`
- `getAllNotes()` - 获取所有笔记
- `queryNotes(NoteQuery)` - 条件查询
- `getRecentNotes()` - 最近笔记
- `getFavoriteNotes()` - 收藏笔记
- `createNote()` / `updateNote()` / `deleteNote()` - CRUD
- `toggleFavorite()` - 切换收藏

**UseCase**: `CreateNoteUseCase`
- 处理图片本地化
- 创建类型标签 (如不存在)
- 创建笔记记录

**Providers**:
- `noteRepositoryProvider` - Repository 实例
- `notesByQueryProvider` - 按条件查询
- `recentNotesProvider` - 最近笔记
- `favoriteNotesProvider` - 收藏笔记
- `paginatedNotesProvider` - 分页加载

#### Tags 模块

标签管理功能。

**实体**: `Tag`

**Repository 接口**: `TagRepository`
- `getTagsByCategory()` - 按分类获取
- `getTagByName()` - 按名称查找
- `safeDeleteTag()` - 安全删除 (检查是否被使用)

**异常**: `TagInUseException` - 标签被使用时抛出

#### Filters 模块

筛选器功能。

**实体**: `SavedFilter`, `FilterOptions`

**Repository 接口**: `SavedFilterRepository`

### 4. Shared 层 (`lib/shared/`)

跨模块共享的功能。

```
shared/
├── data/
│   └── repositories/
│       └── recent_usage_repository_impl.dart
├── domain/
│   └── repositories/
│       └── recent_usage_repository.dart
└── providers/
    ├── database_provider.dart        # 数据库 Provider
    ├── recent_usage_providers.dart   # 最近使用 Provider
    └── services_provider.dart        # 服务 Provider
```

## 数据流

### 读取数据流

```
UI (Page/Widget)
    │
    ▼
Provider (Riverpod)
    │
    ▼
Repository Interface
    │
    ▼
Repository Implementation
    │
    ▼
DAO (Drift)
    │
    ▼
Database (SQLite)
```

### 写入数据流 (通过 UseCase)

```
UI (Page/Widget)
    │
    ▼
UseCase
    │
    ├──▶ Service (图片本地化等)
    │
    ▼
Repository
    │
    ▼
Database
```

## 状态管理

使用 Riverpod 进行状态管理，主要模式：

### 1. Repository Provider

```dart
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NoteRepositoryImpl(db);
});
```

### 2. Async Data Provider

```dart
final notesByQueryProvider = FutureProvider.family<List<Note>, NoteQuery>((ref, query) async {
  ref.watch(notesRefreshTickProvider);  // 刷新触发器
  final repository = ref.watch(noteRepositoryProvider);
  return repository.queryNotes(query);
});
```

### 3. StateNotifier Provider (分页)

```dart
final paginatedNotesProvider = StateNotifierProvider.family<
    PaginatedNotesNotifier, AsyncValue<List<Note>>, NoteQuery>((ref, query) {
  final repository = ref.watch(noteRepositoryProvider);
  return PaginatedNotesNotifier(repository: repository, query: query);
});
```

### 4. 刷新机制

使用 `notesRefreshTickProvider` 作为刷新触发器：

```dart
final notesRefreshTickProvider = StateProvider<int>((ref) => 0);

// 触发刷新
ref.read(notesRefreshTickProvider.notifier).state++;
```

## 路由管理

使用 go_router 进行声明式路由：

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (c, s) => const HomePage()),
      GoRoute(path: '/create', builder: (c, s) => const CreateNotePage()),
      GoRoute(
        path: '/flow',
        builder: (c, s) {
          final extra = s.extra;
          if (extra is NoteQuery) {
            return FlowPage(query: extra);
          }
          return const FlowPage();
        },
      ),
      // ...
    ],
  );
});
```

**参数传递**:
- 简单参数: `state.pathParameters['id']`
- 复杂对象: `state.extra` (NoteQuery)

## 数据库设计

### Drift ORM

使用 Drift (原 Moor) 作为 SQLite ORM：

```dart
@DriftDatabase(tables: [Notes, Tags, SavedFilters, RecentUsages])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertSeedData();
      },
    );
  }
}
```

### 类型转换器

用于复杂类型的存储：

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

### 枚举持久化

使用 `dbCode` 模式确保枚举值的稳定性：

```dart
enum TradeDirection {
  long(dbCode: 'L', displayName: '做多'),
  short(dbCode: 'S', displayName: '做空'),
  observe(dbCode: 'O', displayName: '观察');

  final String dbCode;
  
  static TradeDirection? fromDbCode(String? dbCode) {
    return values.firstWhere((e) => e.dbCode == dbCode);
  }
}
```

## 服务层

### LocalFileService

负责图片文件的本地管理：

- `copyImageToAppDirectory()` - 复制图片到应用目录
- `imageExists()` - 检查图片是否存在
- `deleteImage()` - 删除图片
- `getAllStoredImages()` - 获取所有存储的图片

### CleanupService

负责清理孤立文件：

- `findOrphanedImages()` - 查找孤立图片
- `cleanupOrphanedImages()` - 清理超过指定天数的孤立图片

## 异常处理

自定义异常体系：

```dart
class AppException implements Exception {
  final String message;
  final String? code;
}

class TagInUseException extends AppException {
  final String tagId;
  final int noteCount;
}

class FileNotFoundException extends AppException {
  final String path;
}
```

## 依赖关系

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Features   │────▶│     Core     │◀────│    Shared    │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                    │
       │                    │                    │
       ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────┐
│                   External Packages                  │
│  (Riverpod, go_router, Drift, image_picker, etc.)   │
└─────────────────────────────────────────────────────┘
```

**规则**:
- Features 可以依赖 Core
- Shared 可以依赖 Core
- Features 和 Shared 不直接相互依赖
- Core 不依赖任何业务模块
