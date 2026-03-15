# 图流复盘 (Chart Flow)

一款以图片为核心的交易复盘应用，帮助交易者快速记录、分类和回顾交易案例。

## 功能特性

- **图片主导**：以截图为核心，快速导入交易图表
- **垂直滑动浏览**：类似短视频的 Flow 页面，上下滑动查看笔记
- **智能标签**：支持类型、品种、周期、方向、结果等多维度标签
- **灵活筛选**：组合多个条件快速定位目标笔记
- **收藏功能**：标记重要案例，快速访问
- **本地存储**：数据完全存储在本地，保护隐私

## 技术栈

- **框架**: Flutter 3.2+
- **状态管理**: Riverpod 2.4+ / flutter_riverpod
- **路由**: go_router 13.0+
- **数据库**: Drift (SQLite) 2.14+
- **图片选择**: image_picker 1.0+
- **依赖注入**: Riverpod Provider
- **UUID**: uuid 4.2+
- **国际化**: intl 0.18+

## 项目结构

```
lib/
├── main.dart                     # 应用入口
├── app/                          # 应用层
│   ├── app.dart                  # 主应用 Widget
│   ├── router/
│   │   └── app_router.dart       # go_router 路由配置
│   └── theme/
│       └── app_theme.dart        # 明暗主题配置
├── core/                         # 核心层
│   ├── constants/
│   │   ├── app_constants.dart    # 应用常量
│   │   └── enums.dart            # 枚举定义 (含 dbCode)
│   ├── data/
│   │   ├── converters/
│   │   │   └── string_list_converter.dart  # List<String> 类型转换器
│   │   ├── database/
│   │   │   ├── database.dart     # Drift 数据库定义
│   │   │   ├── database.g.dart   # 生成的数据库代码
│   │   │   └── tables.dart       # 表定义
│   │   └── dao/
│   │       ├── note_dao.dart     # 笔记数据访问
│   │       ├── tag_dao.dart      # 标签数据访问
│   │       ├── saved_filter_dao.dart  # 筛选器数据访问
│   │       └── recent_usage_dao.dart    # 最近使用数据访问
│   ├── domain/
│   │   └── entities.dart         # 领域实体 (Note, Tag, SavedFilter, NoteQuery)
│   ├── errors/
│   │   └── exceptions.dart       # 自定义异常
│   ├── services/
│   │   ├── cleanup_service.dart     # 孤立文件清理服务
│   │   └── local_file_service.dart  # 本地文件管理服务
│   └── widgets/
│       ├── empty_state_widget.dart  # 空状态组件
│       ├── image_picker_card.dart   # 图片选择卡片
│       └── tag_selector.dart        # 标签选择器
├── features/                     # 功能模块
│   ├── filters/                  # 筛选器模块
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── saved_filter_repository_impl.dart
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── saved_filter_repository.dart
│   │   ├── presentation/
│   │   │   └── pages/
│   │   │       ├── filter_page.dart
│   │   │       └── saved_filters_page.dart
│   │   └── providers/
│   │       └── filter_providers.dart
│   ├── home/
│   │   └── presentation/
│   │       └── pages/
│   │           └── home_page.dart
│   ├── notes/                    # 笔记模块
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── note_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── note_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_note_usecase.dart
│   │   │       └── query_notes_usecase.dart
│   │   ├── presentation/
│   │   │   └── pages/
│   │   │       ├── create_note_page.dart
│   │   │       ├── edit_note_page.dart
│   │   │       └── flow_page.dart
│   │   └── providers/
│   │       ├── note_providers.dart
│   │       └── paginated_notes_provider.dart
│   ├── settings/
│   │   └── presentation/
│   │       └── pages/
│   │           └── settings_page.dart
│   └── tags/                     # 标签模块
│       ├── data/
│       │   └── repositories/
│       │       └── tag_repository_impl.dart
│       ├── domain/
│       │   └── repositories/
│       │       └── tag_repository.dart
│       ├── presentation/
│       │   └── pages/
│       │       └── tags_page.dart
│       └── providers/
│           └── tag_providers.dart
└── shared/                       # 共享模块
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

## 快速开始

### 环境要求

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- Android Studio / VS Code / Xcode

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd noteApp
```

2. 安装依赖
```bash
flutter pub get
```

3. 生成数据库代码
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. 运行应用
```bash
flutter run
```

## 核心模块说明

### 笔记 (Notes)

笔记是应用的核心数据单元，包含：
- 图片路径 (imagePath)
- 类型标签 (typeTagId, typeNameSnapshot)
- 品种 (symbol)
- 周期 (timeframe)
- 交易时间 (tradeTime)
- 方向 (direction: Long/Short/Observe)
- 结果 (result: Profit/Loss/Observe/Missed)
- 文字备注 (note)
- 收藏状态 (favorite)
- 归档状态 (archived)

### 标签 (Tags)

标签分为四类：
- **类型 (type)**: 交易类型，如突破、回调、震荡等
- **品种 (symbol)**: 交易品种，如 RB、FG、M 等
- **周期 (timeframe)**: K 线周期，如 5m、15m、30m、1d 等
- **结果 (result)**: 交易结果，盈利、亏损、观察、错过

内置标签在数据库初始化时自动插入。

### 筛选器 (Filters)

支持组合以下条件进行筛选：
- 类型 (多选)
- 品种 (多选)
- 周期 (多选)
- 方向 (多选): Long/Short/Observe
- 结果 (多选): Profit/Loss/Observe/Missed
- 仅收藏 (favoriteOnly)
- 时间范围 (startTime, endTime)
- 关键词搜索 (keyword)

筛选条件可保存为 SavedFilter 供后续快速使用。

### NoteQuery

统一的查询条件对象，用于路由传参和数据库查询：

```dart
class NoteQuery {
  final List<String> typeIds;
  final List<String> symbols;
  final List<String> timeframes;
  final List<TradeDirection> directions;
  final List<TradeResult> results;
  final bool? favoriteOnly;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? keyword;
  final bool? archived;
}
```

### Flow 页面

核心浏览页面，特点：
- 垂直滑动切换笔记 (PageView)
- 全屏图片展示
- 底部显示标签和备注
- 右上角显示页码 (当前/总数)
- 支持收藏操作
- 黑色背景，沉浸式体验

### 首页 (HomePage)

首页包含：
- 快速操作卡片 (Flow、Filter)
- 最近笔记 (横向滚动)
- 收藏笔记 (ActionChip 列表)
- 搜索功能 (关键词搜索)
- 设置入口

## 数据库设计

### Notes 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT | 主键 |
| image_path | TEXT | 图片本地路径 |
| type_tag_id | TEXT | 类型标签 ID |
| type_name_snapshot | TEXT | 类型名称快照 |
| symbol | TEXT | 品种 (可空) |
| timeframe | TEXT | 周期 (可空) |
| trade_time | DATETIME | 交易时间 (可空) |
| direction | TEXT | 方向 (L/S/O, 可空) |
| result | TEXT | 结果 (P/L/O/M, 可空) |
| note | TEXT | 备注 (可空) |
| favorite | BOOL | 是否收藏 (默认 false) |
| archived | BOOL | 是否归档 (默认 false) |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

### Tags 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT | 主键 |
| category | TEXT | 分类 (type/symbol/timeframe/result) |
| name | TEXT | 名称 |
| sort_order | INT | 排序 (默认 0) |
| is_builtin | BOOL | 是否内置 (默认 false) |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

### SavedFilters 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT | 主键 |
| name | TEXT | 名称 |
| type_ids | TEXT (JSON) | 类型 ID 列表 |
| symbols | TEXT (JSON) | 品种列表 |
| timeframes | TEXT (JSON) | 周期列表 |
| directions | TEXT (JSON) | 方向列表 |
| results | TEXT (JSON) | 结果列表 |
| favorite_only | BOOL | 仅收藏 (默认 false) |
| start_time | DATETIME | 开始时间 |
| end_time | DATETIME | 结束时间 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

### RecentUsages 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT | 主键 |
| category | TEXT | 分类 |
| item_id | TEXT | 项目 ID |
| used_at | DATETIME | 使用时间 |

## 枚举持久化策略

枚举使用 `dbCode` 字段进行数据库存储，确保稳定性：

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

方向存储为 L/S/O，结果存储为 P/L/O/M (Profit/Loss/Observe/Missed)。

## 类型转换器

使用 Drift TypeConverter 处理复杂类型：

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

用于 SavedFilters 表的 List<String> 字段 (type_ids, symbols 等)。

## 状态管理

使用 Riverpod 进行状态管理：

### Repository Provider
```dart
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NoteRepositoryImpl(db);
});
```

### Async Data Provider
```dart
final notesByQueryProvider = FutureProvider.family<List<Note>, NoteQuery>((ref, query) async {
  ref.watch(notesRefreshTickProvider);  // 刷新触发器
  final repository = ref.watch(noteRepositoryProvider);
  return repository.queryNotes(query);
});
```

### 分页 Provider
```dart
final paginatedNotesProvider = StateNotifierProvider.family<
    PaginatedNotesNotifier, AsyncValue<List<Note>>, NoteQuery>((ref, query) {
  final repository = ref.watch(noteRepositoryProvider);
  return PaginatedNotesNotifier(repository: repository, query: query);
});
```

### 刷新机制
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
      GoRoute(path: '/', name: 'home', builder: (c, s) => const HomePage()),
      GoRoute(path: '/create', name: 'create', builder: (c, s) => const CreateNotePage()),
      GoRoute(path: '/note/:id/edit', name: 'edit', builder: (c, s) {
        final id = s.pathParameters['id'] ?? '';
        return EditNotePage(noteId: id);
      }),
      GoRoute(path: '/flow', name: 'flow', builder: (c, s) {
        final extra = s.extra;
        if (extra is NoteQuery) {
          return FlowPage(query: extra);
        }
        return const FlowPage();
      }),
      // ...
    ],
  );
});
```

### 路由传参

- 简单参数：`state.pathParameters['id']`
- 复杂对象：`state.extra` (NoteQuery)

示例：
```dart
// 跳转到 Flow 页面并传递筛选条件
context.push('/flow', extra: NoteQuery(typeIds: ['type-1'], favoriteOnly: true));
```

## 服务层

### LocalFileService

负责图片文件的本地管理：

```dart
class LocalFileService {
  // 复制图片到应用目录
  Future<String> copyImageToAppDirectory(String sourcePath);
  
  // 检查图片是否存在
  Future<bool> imageExists(String imagePath);
  
  // 删除图片
  Future<void> deleteImage(String imagePath);
  
  // 获取所有存储的图片
  Future<List<String>> getAllStoredImages();
}
```

### CleanupService

负责清理孤立文件：

```dart
class CleanupService {
  // 查找孤立图片
  Future<List<String>> findOrphanedImages();
  
  // 清理超过指定天数的孤立图片
  Future<int> cleanupOrphanedImages({int maxAgeDays = 7});
}
```

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
  // 标签正在被 noteCount 条笔记使用，无法删除
}

class FileNotFoundException extends AppException {
  final String path;
}
```

## 构建发布

### Android
```bash
flutter build apk --release
```

或生成 App Bundle：
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 代码生成

项目使用代码生成工具，修改数据库定义或实体后需重新生成：

```bash
# 一次性生成
flutter pub run build_runner build --delete-conflicting-outputs

# 持续监听
flutter pub run build_runner watch --delete-conflicting-outputs
```

生成的文件：
- `database.g.dart` - Drift 数据库代码
- `note_dao.g.dart` - Note DAO 代码
- `tag_dao.g.dart` - Tag DAO 代码
- `saved_filter_dao.g.dart` - SavedFilter DAO 代码
- `recent_usage_dao.g.dart` - RecentUsage DAO 代码

## 权限配置

### Android

在 `android/app/src/main/AndroidManifest.xml` 中已配置：

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

## 开发规范

### 命名约定

- 文件命名：snake_case (如 `note_repository.dart`)
- 类命名：PascalCase (如 `NoteRepository`)
- 变量/函数：camelCase (如 `getNoteById`)
- 常量：PascalCase (如 `AppConstants`)

### 目录约定

- 按功能模块划分 (feature-first)
- 每个模块包含 data/domain/presentation/providers
- 共享组件放在 core/widgets
- 共享服务放在 core/services

## 许可证

MIT License
