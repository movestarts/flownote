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
- **状态管理**: Riverpod 2.4+
- **路由**: go_router 13.0+
- **数据库**: Drift (SQLite)
- **图片选择**: image_picker

## 项目结构

```
lib/
├── app/                          # 应用层
│   ├── app.dart                  # 主应用 Widget
│   ├── router/                   # 路由配置
│   └── theme/                    # 主题配置
├── core/                         # 核心层
│   ├── constants/                # 常量和枚举
│   ├── data/                     # 数据层基础设施
│   │   ├── converters/           # 类型转换器
│   │   ├── database/             # 数据库定义
│   │   └── dao/                  # 数据访问对象
│   ├── domain/                   # 领域实体
│   ├── errors/                   # 异常定义
│   ├── services/                 # 服务层
│   └── widgets/                  # 通用组件
├── features/                     # 功能模块
│   ├── filters/                  # 筛选器模块
│   ├── home/                     # 首页模块
│   ├── notes/                    # 笔记模块
│   ├── settings/                 # 设置模块
│   └── tags/                     # 标签模块
└── shared/                       # 共享模块
    ├── data/
    ├── domain/
    └── providers/
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- Android Studio / Xcode (用于模拟器或真机调试)

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
- 图片路径
- 类型标签 (必填)
- 品种、周期
- 交易时间、方向、结果
- 文字备注
- 收藏状态

### 标签 (Tags)

标签分为四类：
- **类型 (type)**: 交易类型，如突破、回调、震荡等
- **品种 (symbol)**: 交易品种，如 RB、FG 等
- **周期 (timeframe)**: K线周期，如 5m、15m、1d 等
- **结果 (result)**: 交易结果，盈利、亏损、观察等

### 筛选器 (Filters)

支持组合以下条件进行筛选：
- 类型 (多选)
- 品种 (多选)
- 周期 (多选)
- 方向 (多选)
- 结果 (多选)
- 仅收藏
- 时间范围
- 关键词搜索

### Flow 页面

核心浏览页面，特点：
- 垂直滑动切换笔记
- 全屏图片展示
- 底部显示标签和备注
- 支持收藏操作

## 数据库设计

### Notes 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT | 主键 |
| image_path | TEXT | 图片本地路径 |
| type_tag_id | TEXT | 类型标签ID |
| type_name_snapshot | TEXT | 类型名称快照 |
| symbol | TEXT | 品种 |
| timeframe | TEXT | 周期 |
| trade_time | DATETIME | 交易时间 |
| direction | TEXT | 方向 (L/S/O) |
| result | TEXT | 结果 (P/L/O/M) |
| note | TEXT | 备注 |
| favorite | BOOL | 是否收藏 |
| archived | BOOL | 是否归档 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

### Tags 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT | 主键 |
| category | TEXT | 分类 |
| name | TEXT | 名称 |
| sort_order | INT | 排序 |
| is_builtin | BOOL | 是否内置 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

### SavedFilters 表
存储用户保存的筛选条件组合。

### RecentUsages 表
记录最近使用的项目，用于快速访问。

## 枚举持久化策略

枚举使用 `dbCode` 字段进行数据库存储，确保稳定性：

```dart
enum TradeDirection {
  long(dbCode: 'L', displayName: '做多'),
  short(dbCode: 'S', displayName: '做空'),
  observe(dbCode: 'O', displayName: '观察');
  
  final String dbCode;
  final String displayName;
}
```

## 构建发布

### Android
```bash
flutter build apk --release
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

## 许可证

MIT License
