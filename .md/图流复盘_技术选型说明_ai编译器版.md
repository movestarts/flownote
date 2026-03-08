# 图流复盘 App 技术选型说明（AI 编译器版）

## 1. 文档目的
本文件不是给人阅读的技术分析报告，而是给 AI 编程工具直接使用的项目技术约束文档。

目标：
- 让 AI 基于统一技术栈生成 Android 优先的 MVP
- 降低技术分歧和无关发挥
- 避免过度设计
- 保证首版专注于“图片导入 + 标签 + 刷流 + 筛选”闭环

---

## 2. 项目结论

### 2.1 最终技术选型
本项目首版固定采用以下技术栈：

- **客户端框架**：Flutter
- **目标平台**：Android 优先
- **状态管理**：Riverpod
- **路由**：go_router
- **本地数据库**：Isar
- **图片选择**：image_picker
- **本地路径管理**：path_provider
- **权限处理**：permission_handler
- **时间处理**：intl
- **唯一 ID**：uuid

### 2.2 选型原则
AI 必须遵守以下原则：

1. 优先快速实现 MVP，不做企业级过度架构
2. 优先本地能力，不接入后端
3. 优先 Android 可用性，不做多端差异化优化
4. 优先可维护的简单代码，不炫技
5. 优先结构化数据，不堆砌自由文本

---

## 3. 为什么不用其他技术栈

### 3.1 不使用 Jetpack Compose 的原因
虽然本项目 Android 优先，但首版不使用原生 Android / Jetpack Compose，原因如下：

- 目标是快速做出 MVP，而不是深耕 Android 原生生态
- 需要更适合 AI 生成和快速迭代的统一 UI 框架
- Flutter 更适合后续保留 iOS 扩展可能
- 当前阶段不需要重度系统级原生能力

### 3.2 不使用 React Native 的原因
- 对图片流、本地文件、本地数据库的一致性体验不如 Flutter 稳
- 个人项目下，RN 的依赖兼容和原生桥问题更容易增加维护成本
- 本项目不是 web 思维迁移型产品

### 3.3 不使用 SQLite + 原生 SQL 的首版原因
首版不优先使用 Drift / SQLite，而使用 Isar，原因：

- MVP 查询模型较简单：按字段筛选、排序、收藏、最近使用
- Isar 对对象存储和快速 CRUD 更适合首版
- AI 生成和维护成本更低

说明：后续如复杂统计和组合查询增多，可迁移到 Drift。

---

## 4. AI 必须遵守的架构边界

### 4.1 首版必须做
- 本地图片导入
- 本地数据库持久化
- 图片笔记 CRUD
- 标签体系
- 按条件筛选
- 流式刷图浏览
- 收藏功能
- 最近使用标签

### 4.2 首版禁止做
AI 不允许主动加入以下内容，除非明确要求：

- 登录注册
- 云同步
- 用户系统
- 后端 API
- 社区功能
- 多人协作
- AI 自动识别图像
- OCR
- 复杂统计页
- 图表分析
- 自动交易建议
- 复杂动画系统
- 主题系统的深度配置
- 插件化架构
- DDD / 过度 clean architecture
- Repository / Service / UseCase 层无限拆分

### 4.3 代码风格要求
- 代码必须可运行、可读、可维护
- 文件不要过大，但也不要为“优雅”过度拆分
- 优先 feature-first 目录结构
- 优先简单明确的命名
- 所有核心字段保持结构化
- 页面先做通，再做美化

---

## 5. 目标产品范围

本项目是一个：

**图片主导的交易复盘 App**

核心能力：
- 导入 K 线截图
- 为图片打标签
- 保存为结构化笔记
- 按标签和条件进入图片流浏览
- 高频复盘自己的交易样本

不是：
- 长文档笔记软件
- 社区产品
- 量化交易平台
- 数据分析平台
- AI 自动交易产品

---

## 6. 数据模型（首版固定）

### 6.1 Note
```dart
class Note {
  String id;
  String imagePath;
  String type;
  String? symbol;
  String? timeframe;
  DateTime? tradeTime;
  String? direction; // long / short / observe
  String? result; // win / loss / missed / observe
  String? note;
  bool favorite;
  bool archived;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 6.2 TypeTag
```dart
class TypeTag {
  String id;
  String name;
  int sortOrder;
  DateTime createdAt;
}
```

### 6.3 SavedFilter
```dart
class SavedFilter {
  String id;
  String name;
  List<String>? types;
  List<String>? symbols;
  List<String>? timeframes;
  List<String>? directions;
  List<String>? results;
  bool? onlyFavorite;
  DateTime? startTime;
  DateTime? endTime;
  DateTime createdAt;
}
```

### 6.4 最近使用记录
可单独存储，也可轻量存在本地配置中：
- recentTypes
- recentSymbols
- recentTimeframes

---

## 7. 页面清单（首版固定）

首版只允许存在以下页面：

1. **首页 HomePage**
2. **创建笔记页 CreateNotePage**
3. **刷流页 FeedPage**
4. **筛选页 FilterPage**
5. **笔记详情/编辑页 NoteDetailPage**
6. **设置页 SettingsPage（极简）**

AI 不要额外生成多余页面。

---

## 8. 页面职责说明

### 8.1 HomePage
职责：
- 导入图片入口
- 继续刷样本入口
- 常用 type 快捷入口
- 最近新增样本
- 收藏入口
- 搜索入口

禁止：
- 文档列表式复杂布局
- 大量统计卡片
- 复杂 banner

### 8.2 CreateNotePage
职责：
- 预览已选图片
- 选择 type
- 选择 symbol
- 选择 timeframe
- 选择 tradeTime
- 选择 direction
- 选择 result
- 填写一句话备注
- 保存

要求：
- 尽量一屏完成
- 优先 chip / tag 选择，不要强制大量输入
- 支持最近使用快捷选择

### 8.3 FeedPage
职责：
- 全屏显示当前图片
- 展示核心信息浮层
- 切换上一条/下一条
- 收藏
- 编辑
- 删除

要求：
- 图片优先展示
- 支持流式浏览
- UI 接近内容消费，不是表格或办公软件

### 8.4 FilterPage
职责：
- 按 type / symbol / timeframe / result / direction / time range / favorite 筛选
- 保存筛选条件
- 开始刷

要求：
- 筛选逻辑明确
- 支持组合筛选
- 支持保存常用视图

### 8.5 NoteDetailPage
职责：
- 查看完整字段
- 编辑
- 删除

### 8.6 SettingsPage
职责：
- 管理基础设置
- 查看 App 版本
- 导出能力预留入口（可先占位）

禁止：
- 复杂账户管理
- 多语言管理
- 高级开发者配置

---

## 9. 推荐目录结构

AI 必须按 feature-first 结构生成项目：

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  core/
    constants/
    utils/
    widgets/
    services/
  data/
    models/
    database/
    repositories/
  features/
    home/
      presentation/
      providers/
    create_note/
      presentation/
      providers/
    feed/
      presentation/
      providers/
    filter/
      presentation/
      providers/
    note_detail/
      presentation/
      providers/
    settings/
      presentation/
  shared/
    providers/
```

说明：
- 不要求严格 clean architecture
- 不要拆出过多 domain/usecase 层
- repository 数量保持最少
- 优先简洁可维护

---

## 10. 状态管理规则

使用 **Riverpod**。

### 原则
- 页面状态由对应 feature 的 provider 管理
- 全局少量共享状态可放在 shared/providers
- 不要使用多个状态管理方案混搭
- 不要引入 bloc、getx、mobx

### 推荐 provider 类型
- 异步列表/查询：AsyncNotifier / FutureProvider
- 表单状态：Notifier / StateNotifier
- 筛选条件：StateNotifier

---

## 11. 路由规则

使用 **go_router**。

推荐路由：

```text
/
/create
/feed
/filter
/note/:id
/settings
```

要求：
- 路由清晰简单
- 不要生成复杂嵌套路由树
- 不要过早引入 shell route

---

## 12. 本地数据库规则

使用 **Isar**。

### 数据要求
- 所有 Note 必须本地持久化
- 支持按字段查询
- 支持按创建时间倒序
- 支持按 favorite 过滤
- 支持组合筛选

### 数据操作要求
必须支持：
- 新建 Note
- 更新 Note
- 删除 Note
- 查询单条 Note
- 查询最近新增 Notes
- 按条件查询 Feed
- 收藏/取消收藏
- 保存/读取 SavedFilter

---

## 13. 图片处理规则

### 首版方案
- 图片只保存本地路径
- 不做图片上传
- 不做云端备份
- 不做图片压缩链路优化的复杂处理

### 导入方式
- 相册选择
- 系统分享进入 App（可放在第二阶段）

### 要求
- 图片导入后应立即进入创建流程
- Feed 页全屏展示图片时要注意 fit 策略
- 不要对图片做多余加工

---

## 14. UI 规则

### 14.1 视觉方向
- 深色主题优先
- 图片为视觉主角
- 信息悬浮层半透明
- 卡片与圆角保持统一
- 风格简洁、克制、现代

### 14.2 交互方向
- 录入快
- 切换快
- 筛选快
- 不要复杂手势冲突

### 14.3 禁止项
- 不要拟物化
- 不要过度动画
- 不要复杂渐变和重装饰
- 不要做成办公软件风格
- 不要做成长文笔记编辑器

---

## 15. 开发阶段拆解（AI 必须按阶段执行）

## Phase 1：项目初始化
目标：创建可运行 Flutter 工程

必须完成：
- Flutter 项目初始化
- 依赖配置
- 基础主题
- go_router 配置
- Riverpod 配置
- Isar 初始化
- 基础目录结构搭建

## Phase 2：数据层
目标：先把本地数据能力跑通

必须完成：
- Note / TypeTag / SavedFilter 模型
- Isar collection 定义
- 本地 CRUD
- 查询接口
- 最近使用标签存储

## Phase 3：创建流程
目标：先解决“记一条图”

必须完成：
- 图片导入
- CreateNotePage
- 标签选择
- 保存笔记
- 保存成功反馈

## Phase 4：首页
目标：先有基本入口和列表

必须完成：
- 导入图片入口
- 最近新增列表
- 常用 type 入口
- 收藏入口

## Phase 5：刷流页
目标：先验证核心体验

必须完成：
- FeedPage
- 单图展示
- 核心字段浮层
- 上一条/下一条切换
- 收藏/编辑/删除

## Phase 6：筛选页
目标：形成“专题样本流”

必须完成：
- 条件筛选
- 组合筛选
- 保存常用视图
- 跳转进入 Feed

## Phase 7：编辑和优化
目标：补全 MVP 闭环

必须完成：
- NoteDetailPage
- 编辑笔记
- 删除确认
- 搜索
- 最近使用优化
- 空状态/异常状态

---

## 16. AI 生成代码时的限制

AI 必须严格遵守以下限制：

1. 不要生成后端代码
2. 不要假设网络 API 存在
3. 不要生成登录流程
4. 不要引入与项目无关的大型依赖
5. 不要在首版加入复杂测试体系
6. 不要为了“架构优雅”引入过多抽象层
7. 不要在没有要求时引入动画库
8. 不要擅自修改数据模型核心字段
9. 不要在 MVP 阶段做自动识别和 AI 能力
10. 所有实现必须围绕“图片 + 标签 + 刷流 + 筛选”服务

---

## 17. 首版验收标准

AI 实现完成后，必须满足以下验收条件：

1. 可以在 Android 真机或模拟器运行
2. 可以从相册导入图片
3. 可以创建并保存一条图片笔记
4. 可以查看最近新增笔记
5. 可以进入指定条件下的 Feed 流
6. 可以收藏和取消收藏
7. 可以编辑和删除笔记
8. 可以保存并复用筛选条件
9. 页面结构清晰、运行稳定
10. 没有多余复杂功能

---

## 18. 后续可扩展方向（仅预留，不实现）

以下内容仅允许在架构上留扩展空间，不允许首版实现：

- OCR
- AI 自动标签建议
- 云同步
- 图片多端同步
- 训练模式
- 多图关联案例
- 统计页
- 数据导出

---

## 19. 一句话执行指令

> 使用 Flutter 构建一个 Android 优先的图片主导交易复盘 App MVP。严格采用 Riverpod + go_router + Isar 技术栈。只实现本地图片导入、结构化笔记、标签、筛选、刷流、收藏、编辑删除，不做后端、不做 AI、不做云同步、不做过度架构。先做可运行，再做优化。

