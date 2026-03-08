可以。下面这份不是给人看的“泛泛计划”，而是给 AI 编译器直接执行的**实现计划 / Implementation Plan**。我会把它写成偏工程交付格式，目标是让 AI 按阶段落地，而不是只产出一堆空壳页面。

这份实现计划严格围绕你的 PRD 核心闭环展开：**图片导入 → 标注保存 → 条件筛选 → 流式刷图**，并刻意收敛第一版范围，不碰云同步、账号系统、AI 识别、社区等非 MVP 内容。  

---

# 图片主导交易复盘 App 实现计划（给 AI 编译器）

## 1. 项目目标

实现一个可运行的 Android 优先 Flutter MVP，满足以下最小闭环：

1. 用户可从相册导入图片创建笔记
2. 用户可为图片设置结构化字段并保存
3. 用户可查看、编辑、删除笔记
4. 用户可按 type、品种、周期、时间、方向、结果、收藏状态筛选
5. 用户可在筛选结果下进入全屏流式浏览页面，上下滑切换样本
6. 用户可保存常用筛选条件
7. 用户可管理基础标签数据
8. 所有数据本地持久化，图片只保存本地路径

该实现必须围绕“图片第一，文字第二，刷流优先”的产品原则，不允许退化成传统列表式笔记 App。 

---

## 2. 版本边界

## 2.1 本次必须实现

依据 PRD 的 MVP 边界，本次只做以下内容：本地图片导入、本地数据库存储、创建/编辑/删除笔记、标签系统、按条件筛选、流式浏览、收藏、最近使用记录。

## 2.2 本次明确不做

以下内容一律不进入本次实现范围：

* 云同步
* 登录注册 / 用户系统
* 社区 / 分享社区
* OCR / AI 自动打标签
* 图表统计页
* 多图关联案例链
* 自动生成交易结论
* 拍照上传
* 左滑切换不同流
* 复杂动画系统

如果 AI 编译器尝试扩展这些内容，视为偏离实现计划。

---

## 3. 技术栈与架构约束

## 3.1 技术选型

按 PRD 的建议，采用以下技术栈：

* Flutter
* Riverpod
* go_router
* SQLite + Drift
* image_picker
* path_provider
* uuid
* freezed / json_serializable（可选，但推荐）
* intl

## 3.2 平台要求

* 优先 Android 真机运行
* iOS 代码可保留兼容，但不作为交付验收重点
* 所有功能必须支持本地离线使用

## 3.3 架构要求

采用 **feature-first + clean-ish** 结构，但禁止过度抽象。优先保证 AI 能持续生成、修改和调试。

推荐目录结构：

```text
lib/
  app/
    app.dart
    router/
    theme/
  core/
    constants/
    utils/
    extensions/
    widgets/
    errors/
  features/
    notes/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        pages/
        widgets/
        providers/
    tags/
      data/
      domain/
      presentation/
    filters/
      data/
      domain/
      presentation/
    home/
      presentation/
    settings/
      presentation/
  shared/
    providers/
```

要求：

* 页面、状态、数据读写按 feature 拆分
* Repository 层必须存在
* 数据库存取不能散落在页面里
* 页面允许直接依赖 provider，但不允许直接写 SQL

---

## 4. 数据模型实现

根据 PRD，第一版至少实现三类核心模型：Note、Tag、SavedFilter。

## 4.1 Note

字段定义：

```text
id: String (uuid)
imagePath: String
typeTagId: String
typeNameSnapshot: String
symbol: String?
timeframe: String?
tradeTime: DateTime?
direction: enum(long, short, observe)?
result: enum(profit, loss, observe, missed)?
note: String?
favorite: bool
archived: bool
createdAt: DateTime
updatedAt: DateTime
```

说明：

* `imagePath` 存本地文件路径
* `typeTagId` 用于关联标签
* `typeNameSnapshot` 作为冗余字段，避免标签被删除后旧笔记无法展示
* `archived` 第一版只保留字段，不做复杂归档页
* `tradeTime` 可为空，但创建时默认当前时间

## 4.2 Tag

第一版只做统一 Tag 表 + type 区分，或直接拆多表，二选一即可，但必须支持以下标签类别：

* type
* symbol
* timeframe
* result

推荐统一表结构：

```text
id: String
category: enum(type, symbol, timeframe, result)
name: String
sortOrder: int
createdAt: DateTime
updatedAt: DateTime
isBuiltin: bool
```

其中：

* `type` 支持用户自定义
* `symbol/timeframe/result` 可预置默认值，并允许扩展

## 4.3 SavedFilter

字段定义：

```text
id: String
name: String
typeIds: List<String>
symbols: List<String>
timeframes: List<String>
directions: List<String>
results: List<String>
favoriteOnly: bool
startTime: DateTime?
endTime: DateTime?
createdAt: DateTime
updatedAt: DateTime
```

要求：

* Drift 中如果不方便存数组，可转 JSON string 存储
* 读取时提供解析层，不允许页面里手写 JSON decode 逻辑

## 4.4 最近使用记录

新增一张轻量表或本地 KV：

* recent_type_ids
* recent_symbols
* recent_timeframes

用于创建页优先展示最近使用项。这个需求来自 PRD 的“最近使用”与“尽量减少输入成本”。 

---

## 5. 页面与路由实现计划

按 PRD 一级页面，第一版实现以下页面。

## 5.1 路由表

```text
/                       首页
/create                  创建笔记页
/note/:id/edit           编辑笔记页
/flow                    刷流页
/filter                  筛选页
/saved-filters           常用筛选列表页（可并入筛选页）
/tags                    标签管理页
/settings                设置页（占位）
```

---

## 6. 分阶段开发任务

---

## Phase 1：项目初始化与基础框架

### 目标

搭建一个可运行的 Flutter 工程，完成主题、路由、数据库基础设施。

### 任务

1. 初始化 Flutter 项目
2. 接入 Riverpod、go_router、Drift
3. 配置深色主题为默认主题
4. 建立 app router
5. 创建基础目录结构
6. 完成数据库初始化与 migration 基础代码
7. 首页、创建页、刷流页、筛选页先做空壳页面可跳转

### 交付标准

* App 可启动
* 页面可正常路由跳转
* 数据库启动无报错
* 深色主题生效
* 工程结构清晰，无单文件堆砌

### 验收条件

* `flutter run` 可正常运行
* 首页有“导入图片”“继续刷”“筛选入口”三个基础入口
* 所有占位页路由可打开

---

## Phase 2：数据层与 Repository 完成

### 目标

先把“数据能存、能查、能改、能删”打牢，页面先简陋也没关系。

### 任务

1. 建立 Drift 表：

   * notes
   * tags
   * saved_filters
   * recent_usages（或用 shared_preferences 替代）
2. 建立 DAO / datasource
3. 建立 repository 接口与实现
4. 完成以下能力：

   * 创建笔记
   * 更新笔记
   * 删除笔记
   * 获取单条笔记
   * 分页或按条件查询笔记
   * 收藏切换
   * 获取最近新增
   * 获取收藏列表
   * CRUD 标签
   * CRUD 常用筛选
5. 写基础 seed 数据：

   * 默认 timeframe：5m / 15m / 30m / 60m
   * 默认 result：profit / loss / observe / missed
   * 默认 direction 枚举无需标签表存储也可

### 交付标准

* 数据层可独立使用
* 查询条件可组合
* 不依赖 UI 即可完成核心功能

### 验收条件

* 至少有 8~10 个 repository 单元测试或集成测试
* 组合筛选正确工作
* 删除笔记后不会误删图片文件，除非显式调用清理逻辑

---

## Phase 3：图片导入与创建笔记流程

### 目标

完成 MVP 最关键入口：5~10 秒内完成一条图片笔记创建。这个要求来自 PRD，必须优先保证。

### 任务

1. 接入 image_picker，从相册选择单张图片
2. 将用户选择的图片复制到 app 私有目录
3. 创建笔记表单页
4. 表单字段实现：

   * 图片预览
   * type（必填）
   * symbol
   * timeframe
   * tradeTime（默认当前时间）
   * direction
   * result
   * note
5. type 选择器支持：

   * 最近使用
   * 已有标签列表
   * 新建 type 标签
6. symbol / timeframe 支持最近使用优先
7. 点击保存后：

   * 写入数据库
   * 更新最近使用记录
   * 弹出操作：继续录入 / 去刷当前 type / 返回首页

### 交互要求

* 尽量单屏完成，不做多步 wizard
* 多用 chips / segmented buttons / bottom sheet
* 减少键盘输入，备注除外
* 任何必填项缺失时阻止保存并高亮提示

### 交付标准

* 用户从选择图片到保存完成路径顺畅
* 表单字段值正确落库
* 最近使用逻辑生效

### 验收条件

* 创建一条完整笔记不超过 10 秒（测试路径）
* type 为必填，其他字段可选
* 保存后的图片路径来自 app 私有目录，不依赖临时 cache 路径

---

## Phase 4：首页聚合与最近内容展示

### 目标

首页不是传统列表，而是一个“马上开始下一步动作”的控制台。

### 任务

1. 首页实现以下模块：

   * 顶部搜索入口
   * 继续刷样本
   * 导入图片主按钮
   * 常用 type 快捷入口
   * 最近新增样本横向列表
   * 收藏入口
2. “继续刷样本”逻辑：

   * 若存在上次浏览流状态，则继续进入上次条件流
   * 若没有，则默认进入最近新增流
3. 常用 type 快捷入口：

   * 基于最近使用 + 样本数排序展示
4. 最近新增样本列表：

   * 显示图片缩略图、type、symbol、timeframe
   * 点击进入编辑或详情

### 交付标准

* 首页首屏突出“导入图片”和“继续刷”
* 页面视觉轻，不做文档式密集列表

### 验收条件

* 用户进入首页 3 秒内能完成下一步动作选择
* 首页首屏至少包含两个强行动作入口

---

## Phase 5：流式刷图页

### 目标

完成产品最核心体验：像刷短视频一样刷自己的交易样本。

### 任务

1. 使用 `PageView.vertical` 实现上下滑流式浏览
2. 支持传入筛选条件查询结果
3. 单张页面布局：

   * 图片全屏优先
   * 底部半透明信息层
   * 右侧操作区
4. 信息层展示：

   * type
   * symbol
   * timeframe
   * tradeTime
   * result
   * note
5. 右侧操作按钮：

   * 收藏/取消收藏
   * 编辑
   * 删除
   * 分享（第一版只做系统图片分享或复制文案，二选一，简单即可）
6. 点击图片区域：

   * 展开/收起更多详情
7. 长按：

   * 快速修改 type / result / favorite
8. 空状态处理：

   * 当前筛选无数据时显示空状态和返回按钮

### 性能要求

* 图片要有缓存策略
* 刷流时不能频繁闪屏
* 大图优先使用 `BoxFit.contain`
* 缩略图和原图可先不分离，但代码应预留扩展点

### 交付标准

* 滑动稳定
* 当前筛选流里的笔记连续浏览正常
* 收藏、编辑、删除可即时反馈

### 验收条件

* 100 条本地样本情况下滑动无明显卡顿
* 删除当前页后能自动切换到合理的下一条
* 编辑返回后当前页信息自动刷新

---

## Phase 6：筛选页与常用筛选

### 目标

让用户快速进入一个“专题样本流”。这也是 PRD 的核心场景之一。

### 任务

1. 实现筛选页
2. 支持字段：

   * type（单选 / 多选）
   * symbol（单选 / 多选）
   * timeframe
   * 时间范围
   * direction
   * result
   * 是否收藏
3. 点击“开始刷”：

   * 跳转到 `/flow`
   * 传递筛选参数
4. 支持保存当前筛选为常用视图
5. 常用视图可：

   * 查看
   * 重命名
   * 删除
   * 点击直接进入刷流
6. 首页可展示部分常用筛选快捷入口

### 交付标准

* 组合筛选结果正确
* 保存筛选后可复用
* 进入流页面的参数一致性正确

### 验收条件

* type + symbol + timeframe + result 组合筛选返回结果正确
* 收藏-only 筛选生效
* 时间范围筛选对 `tradeTime` 生效，不对 `createdAt` 混用

---

## Phase 7：编辑、删除、标签管理完善

### 目标

补齐闭环，确保数据可维护。

### 任务

1. 编辑笔记页复用创建页组件
2. 删除笔记增加二次确认
3. 标签管理页实现：

   * 查看所有 type 标签
   * 新增 type 标签
   * 重命名 type 标签
   * 删除 type 标签
4. 标签删除策略：

   * 若已有笔记使用该标签，不允许硬删；改为软禁用，或提示用户先迁移
5. symbol / timeframe / result 若采用标签表，管理页也可显示，但第一版主要暴露 type 管理

### 交付标准

* 编辑与创建体验一致
* 删除可控
* 标签不会因删除导致历史数据崩坏

### 验收条件

* 编辑保存后 updatedAt 更新
* 被使用中的 type 标签不会直接导致旧笔记展示异常

---

## Phase 8：搜索与细节收尾

### 目标

完成 MVP 最后可用性补强。

### 任务

1. 基础搜索：

   * 备注文本
   * type 名称
   * symbol
2. 搜索入口放首页顶部
3. 提供搜索结果列表或直接进入搜索流
4. 增加设置页基础内容：

   * App 版本
   * 数据库调试入口（开发环境）
   * 导出数据占位（不实现真正导出也行，只保留入口说明）
5. 加入基本错误处理：

   * 图片丢失
   * 数据库异常
   * 空结果
6. 加入启动时数据修复逻辑：

   * 检查图片路径是否存在
   * 标记坏数据但不让 App 崩溃

### 交付标准

* 搜索可用
* MVP 闭环完整
* 异常路径可控

### 验收条件

* 搜索“摸顶难”可匹配 type
* 搜索“RB”可匹配品种
* 搜索备注关键字可匹配 note

---

## 7. 关键工程实现细则

## 7.1 查询模型统一

不要在每个页面手写查询参数，必须定义统一的 `NoteQuery`：

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
}
```

所有列表、流页面、搜索页都基于这个对象查询，避免逻辑分叉。

## 7.2 图片文件处理

要求：

* 用户选图后复制到 app 文档目录，如 `/notes_images/uuid.jpg`
* 数据库存复制后的最终路径
* 删除笔记时默认只删数据库记录，不立即删图片；可做延迟清理机制
* 避免因编辑或异常造成原图丢失

## 7.3 枚举与显示映射

方向、结果等不要在 UI 层到处写字符串，统一管理：

* domain enum
* display extension
* database converter

## 7.4 Provider 规范

每个 feature 至少包括：

* repository provider
* query state provider
* list provider / detail provider
* mutation controller provider

页面层不直接 new controller。

## 7.5 组件复用

至少抽出以下通用组件：

* 图片选择卡片
* 标签选择器
* 底部信息浮层
* 笔记表单
* 空状态组件
* 筛选 section 组件

---

## 8. UI / 交互约束

依据 PRD，视觉要偏深色、沉浸、图片优先，不得做成办公软件。

## 8.1 视觉原则

* 深色主题默认启用
* 图片区域尽可能大
* 文本信息只保留必要字段
* 使用半透明信息层，不用重边框表格
* 操作按钮弱化但可触达

## 8.2 交互原则

* 创建页优先选择，不优先输入
* 刷流页优先滑动，不优先点点点
* 首页优先行动入口，不优先信息堆叠

## 8.3 禁止项

* 禁止用长列表 + 多级文件夹作为主浏览方式
* 禁止首页变成传统笔记时间线
* 禁止创建页做成复杂表单管理后台风格

---

## 9. 测试与验收计划

## 9.1 必测流程

必须覆盖以下端到端流程：

### 流程 A：快速记录

1. 进入首页
2. 导入图片
3. 选择 type
4. 填其他字段
5. 保存
6. 返回首页看到最近新增

### 流程 B：按 type 刷流

1. 首页点击 type 快捷入口
2. 进入对应流
3. 上下滑切换
4. 收藏一条
5. 编辑一条
6. 删除一条

### 流程 C：按条件复盘

1. 进入筛选页
2. 选择 symbol + timeframe + result
3. 开始刷
4. 保存为常用筛选
5. 返回首页从常用筛选再次进入

这些流程直接来自 PRD 的用户流程定义。

## 9.2 质量验收标准

* 无阻断性崩溃
* 笔记 CRUD 正常
* 筛选结果正确
* 刷流不卡死
* 图片路径稳定
* 页面跳转正确
* 深色主题下可读性良好

## 9.3 性能验收

准备 100~300 张本地图片数据压测：

* 首页打开不超过 2 秒
* 流页面首屏加载流畅
* 连续滑动不卡死
* 频繁收藏/编辑后状态不乱

---

## 10. 开发顺序强约束

AI 编译器必须按以下顺序交付，不允许跳步直接堆 UI：

1. 先搭工程与数据库
2. 再完成 repository 和查询模型
3. 再做创建流程
4. 再做刷流页
5. 再做筛选页
6. 最后补首页聚合、搜索、标签管理与细节优化

原因：

* 这个产品的难点不是静态页面，而是“结构化数据 + 查询 + 流式浏览”
* 若先堆 UI，后续一定返工

---

## 11. 每阶段输出物要求

AI 编译器在每个阶段都必须输出：

### 11.1 代码输出

* 完整可编译代码
* 新增依赖说明
* 新建文件清单
* 核心类说明

### 11.2 说明输出

* 本阶段完成了什么
* 哪些需求已覆盖
* 哪些需求暂未覆盖
* 如何手动验证

### 11.3 禁止行为

* 不允许只输出伪代码
* 不允许只生成页面截图代码
* 不允许省略数据库 migration
* 不允许把 TODO 大面积留给后续

---

## 12. 最终交付定义

当且仅当以下条件全部满足，才算 MVP 完成：

1. 可在 Android 设备上运行
2. 用户能导入图片并创建笔记
3. 笔记能持久化保存
4. 用户能编辑、删除、收藏笔记
5. 用户能按条件筛选笔记
6. 用户能在筛选结果中上下滑流式浏览
7. 用户能保存常用筛选
8. 首页能支持“继续刷”“导入图片”“最近新增”“常用 type”
9. 无需联网即可使用全部核心功能

---

## 13. 可以直接扔给 AI 编译器的执行指令

下面这段你可以直接贴给 AI 编译器：

```text
请按以下实现计划开发一个 Flutter Android 优先的 MVP App，目标是“图片主导的交易复盘工具”。

技术栈固定为：
- Flutter
- Riverpod
- go_router
- Drift(SQLite)
- image_picker
- path_provider
- uuid

开发要求：
1. 严格按阶段实现，不要跳步骤
2. 先完成数据层和本地存储，再做 UI
3. 所有数据本地持久化，图片仅保存本地路径
4. 产品核心闭环只有：图片导入、标签标注、结构化保存、条件筛选、流式刷图
5. 不要实现云同步、账号系统、AI识别、统计页、社区、多图关联
6. 页面必须包含：首页、创建页、刷流页、筛选页、标签管理页、编辑页
7. 刷流页必须使用垂直 PageView，实现全屏图片优先展示
8. 创建页必须支持 5~10 秒内完成一条笔记创建，尽量用标签选择而不是大量输入
9. 数据模型至少包含 Note、Tag、SavedFilter、RecentUsage
10. 所有查询统一走 NoteQuery 对象，不允许页面里散写筛选逻辑
11. 代码结构使用 feature-first，必须有 repository 层
12. 每完成一个 Phase，输出：
   - 本阶段新增文件
   - 完成的功能
   - 如何验证
   - 下一阶段计划

开发阶段顺序：
Phase 1：项目初始化、路由、主题、数据库初始化
Phase 2：数据表、DAO、Repository、Query 模型、基础 CRUD
Phase 3：图片导入、创建笔记页、保存流程、最近使用
Phase 4：首页聚合、最近新增、常用 type、继续刷
Phase 5：流式刷图页、收藏/编辑/删除、详情展开
Phase 6：筛选页、组合筛选、保存常用筛选、进入流
Phase 7：编辑页、标签管理页、删除保护
Phase 8：搜索、异常处理、性能优化、收尾

先从 Phase 1 开始，直接输出可运行代码，不要只给方案。
```

---

你这份 PRD 本身方向是对的，真正关键的是把它压成这种 **“AI 可执行的工程计划”**，否则 AI 很容易写成一个好看但不能复盘的笔记壳子。原始需求中最核心的几处——图片主导、流式浏览、type 为核心标签、筛选进入专题流、MVP 边界收敛——我都已经在实现计划里固化成了硬约束。  

你要的话，我下一步可以继续帮你把这份实现计划再升级成一版**“给 AI 编译器的任务拆分文档（每个 Phase 单独 prompt）”**。
