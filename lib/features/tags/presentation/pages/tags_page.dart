import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';
import 'package:chart_flow/features/tags/providers/tag_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

enum _TagSortMode { byName, byUsage }

class TagsPage extends ConsumerStatefulWidget {
  const TagsPage({super.key});

  @override
  ConsumerState<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends ConsumerState<TagsPage> {
  final _nameController = TextEditingController();
  final _uuid = const Uuid();
  _TagSortMode _sortMode = _TagSortMode.byName;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createTag() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(tagRepositoryProvider);
    final existing = await repo.getTagByName(name);
    if (existing != null) return;

    final now = DateTime.now();
    await repo.createTag(
      Tag(
        id: _uuid.v4(),
        name: name,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _nameController.clear();
    ref.invalidate(allTagsProvider);
  }

  Future<void> _renameTag(Tag tag) async {
    final controller = TextEditingController(text: tag.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名标签'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存')),
        ],
      ),
    );
    if (confirmed != true) return;
    final value = controller.text.trim();
    if (value.isEmpty) return;
    await ref.read(tagRepositoryProvider).updateTag(tag.copyWith(name: value));
    ref.invalidate(allTagsProvider);
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('确认删除 "${tag.name}" 吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(tagRepositoryProvider).safeDeleteTag(tag.id);
      ref.invalidate(allTagsProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标签仍被笔记使用，无法删除')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(allTagsProvider);
    final noteRepo = ref.watch(noteRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('标签管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
        data: (tags) => FutureBuilder<Map<String, int>>(
          future: () async {
            final map = <String, int>{};
            for (final tag in tags) {
              map[tag.id] = await noteRepo.getNoteCountByTagId(tag.id);
            }
            return map;
          }(),
          builder: (context, snapshot) {
            final usageMap = snapshot.data ?? <String, int>{};
            final sorted = [...tags];
            if (_sortMode == _TagSortMode.byName) {
              sorted.sort((a, b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            } else {
              sorted.sort((a, b) =>
                  (usageMap[b.id] ?? 0).compareTo(usageMap[a.id] ?? 0));
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: '新标签名称'),
                      ),
                    ),
                    IconButton(
                      onPressed: _createTag,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<_TagSortMode>(
                  segments: const [
                    ButtonSegment(
                        value: _TagSortMode.byName, label: Text('按名称')),
                    ButtonSegment(
                        value: _TagSortMode.byUsage, label: Text('按使用次数')),
                  ],
                  selected: {_sortMode},
                  onSelectionChanged: (value) =>
                      setState(() => _sortMode = value.first),
                ),
                const SizedBox(height: 12),
                ...sorted.map(
                  (tag) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tag.name),
                    subtitle: Text('使用次数: ${usageMap[tag.id] ?? 0}'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: () => _renameTag(tag),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => _deleteTag(tag),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
