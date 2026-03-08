# 架构与当前代码审查记录

基于 PRD、实现计划（Implementation Plan）以及当前 `lib/` 目录下的实际代码，发现以下架构问题、交互潜在风险以及返工点。由于当前工程主要完成了 Phase 1 & 2（搭建了路由、Drift 数据库和 Repository 等数据层，UI 层基本为空壳），我们重点关注已有的数据映射和接下来需要避免的代码逻辑陷阱。

## 1. 架构问题

### 1.1 查询模型（NoteQuery）未在路由/UI层统一
*   **问题所在**：实现计划第 7.1 与 13.10 条明确规定：“不要在每个页面手写查询参数，必须定义统一的 `NoteQuery`... 所有查询统一走 NoteQuery 对象”。但在 `app_router.dart` 中，`/flow` 路由依然接收并且强行解构了分散的参数（`typeIds`, `symbols`, `timeframes` 等），并传递给 `FlowPage`。
*   **修改建议**：重构 `FlowPage` 的构造函数，使其直接接收一个 `NoteQuery` 对象。而在 `go_router` 中，可以直接将 `NoteQuery` 作为 `extra` 参数传递，或实现其 `toJson/fromJson` 进行更安全的底层参数传递。

### 1.2 Repository 职责缺失（图片本地化逻辑）
*   **问题所在**：计划第 7.2 节要求“用户选图后复制到 app 文档目录，数据库存复制后的最终路径”。当前 `NoteRepositoryImpl.createNote` 仅仅将对象透传给 `NoteDao`，并未包含或规划图片本地化的处理层。
*   **修改建议**：应该引入一个独立的 `LocalFileService`，或在 `NoteUseCase` / 领域服务层统一处理图片拷贝。避免直接在 UI 层（例如 `CreateNotePage`）处理文件的 I/O 操作和复制逻辑，以免造成 UI 逻辑臃肿和不可测试。

### 1.3 数据库关系与软限制薄弱
*   **问题所在**：在 `NoteDao` 和 `tables.dart` 中，`typeTagId` 是作为字符串直接存在的，并未设置外键约束。实现计划 Phase 7 要求“已有笔记使用该标签，不允许硬删；改为软禁用”。如果纯靠应用层业务校验，非常容易漏判，导致脏数据（Orphaned Notes）。
*   **修改建议**：虽然为了灵活性取消了硬性外键，但建议在 Repository 实现中加固或封装 `Tag` 的删除方法；如果在 Dao 层删除 Tag 前，优先 `getNoteCountByTypeTagId` 判断并抛出自定义异常。

---

## 2. 交互问题（针对待实现页面的预警）

### 2.1 创建笔记页（Create NotePage）单屏化风险
*   **问题所在**：PRD 要求“记录尽可能轻、减少打字、通过标签/按键输入，一屏完成”。如果接下来的 AI 开发默认采用大量自带键盘弹出的 `TextFormField` 会严重破坏该体验。
*   **修改建议**：后续给 AI编译器生成 UI 的 Prompt 需要明确强调：只能为 `note`（备注）使用键盘输入框，其他所有字段（type、周期、胜负结果等）都必须使用 `ChoiceChip` 或 `SegmentedButton` 组件；时间选择必须提供“默认当前时间”并不强制用户弹窗重选。

### 2.2 刷流页（Flow Page）数据翻页体验
*   **问题所在**：MVP 阶段通过 `PageView.vertical` 上下滑动如果直接使用 `NoteRepository.queryNotes` 一下子加载并构建所有的 List，在多图（如 300 张）环境下会造成内存溢出闪退。
*   **修改建议**：实现 `FlowPage` 时，状态管理器（Riverpod）应采用分页 Provider（如 `Cursor` 或基于索引的分页加载），并在 `PageView.builder` 结构下保持懒加载；同时预定义图片的缓存加载机制如 `ExtendedImage`。

### 2.3 路由传参风险 (go_router)
*   **问题所在**：目前 `FlowPage` 参数在 `app_router.dart` 中使用了 `state.extra` 提取。这在 Flutter Web/DeepLink 中如果通过 URL 访问会导致崩溃，虽然属于离线本地 App 但不利于后期维护路由状态。
*   **修改建议**：如果参数过多无法写进路径作为 query_parameters，保持 `extra` 但加入显式的 null 检查和默认值兜底，避免进入刷流页时闪退。

---

## 3. 潜在返工点

### 3.1 字段枚举与 SQLite 存储方案
*   **由于当前设计**：`direction` 和 `result` 目前在 Dao 层直接转为了 `t.result.isIn(resultNames)` 并存为 SQLite 字符串 `TEXT`。
*   **返工隐患**：未来若重命名某个枚举（如 `missed` 变成 `miss`），数据库中历史留存字段就会读取报错。
*   **建议**：在 Enum 中增加一个固定不变的 `dbCode` 参数，与转换逻辑解耦；或直接存 Int/Index。

### 3.2 List 和 Set 的频繁重构
*   **由于当前设计**：`SavedFilters` 表采用 JSON 字符串格式来存储 `typeIds` 等 List。然而 `saved_filter_dao.dart` 中的具体转换层级（Converter）当前并未在表和 Entity 中显式确认，AI在编写存取代码时容易发生 TypeCastException。
*   **建议**：接下来的任务安排应明确 `TypeConverter<List<String>, String>` 以 JSON 编码的形式直接注入到 `tables.dart` 的 Column 中，不要在 Dao 里手动做 map 和 String 的互转。

### 3.3 图片删除延迟机制未就位
*   **返工隐患**：计划要求“删除笔记默认只删记录不删图片，做延迟清理”。由于缺少专门的文件清理模块，如果在开发删除功能时没注意此要求，顺手在 UI 点击删除时强删了本地图片文件，若该图片存在其它冗余或处于分享流程中，会导致关联错误。
*   **建议**：建议补充一个在启动时校验与自动清理游离图片文件的后台 `CleanupService`，彻底与删除 Note 的操作剥离开。
