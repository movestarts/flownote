import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';
import 'package:chart_flow/features/tags/providers/tag_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditNotePage extends ConsumerStatefulWidget {
  final String noteId;

  const EditNotePage({super.key, required this.noteId});

  @override
  ConsumerState<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends ConsumerState<EditNotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _symbolController = TextEditingController();
  final _timeframeController = TextEditingController();

  DateTime? _tradeTime;
  bool _isFavorite = false;
  Set<String> _selectedTagIds = <String>{};
  Note? _loadedNote;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _symbolController.dispose();
    _timeframeController.dispose();
    super.dispose();
  }

  Future<void> _pickTradeDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _tradeTime ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_tradeTime ?? now),
    );
    setState(() {
      _tradeTime = DateTime(
          date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
    });
  }

  Future<void> _save() async {
    final note = _loadedNote;
    if (note == null) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(noteRepositoryProvider);
      await repo.updateNote(
        note.copyWith(
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          content: _contentController.text.trim().isEmpty
              ? null
              : _contentController.text.trim(),
          symbol: _symbolController.text.trim().isEmpty
              ? null
              : _symbolController.text.trim(),
          timeframe: _timeframeController.text.trim().isEmpty
              ? null
              : _timeframeController.text.trim(),
          tradeTime: _tradeTime,
          isFavorite: _isFavorite,
          tagIds: _selectedTagIds.toList(),
          updatedAt: DateTime.now(),
        ),
      );
      ref.read(notesRefreshTickProvider.notifier).state++;
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Note?>(
      future: ref.read(noteRepositoryProvider).getNoteById(widget.noteId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final note = snapshot.data;
        if (note == null) {
          return const Scaffold(body: Center(child: Text('笔记不存在')));
        }
        if (_loadedNote == null) {
          _loadedNote = note;
          _titleController.text = note.title ?? '';
          _contentController.text = note.content ?? '';
          _symbolController.text = note.symbol ?? '';
          _timeframeController.text = note.timeframe ?? '';
          _tradeTime = note.tradeTime;
          _isFavorite = note.isFavorite;
          _selectedTagIds = note.tagIds.toSet();
        }

        final tagsAsync = ref.watch(allTagsProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('编辑笔记'),
            actions: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: const Text('保存'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '标题'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: '备注'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              tagsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('标签加载失败: $error'),
                data: (tags) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => FilterChip(
                          selected: _selectedTagIds.contains(tag.id),
                          label: Text(tag.name),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTagIds.add(tag.id);
                              } else {
                                _selectedTagIds.remove(tag.id);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(labelText: '品种'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeframeController,
                decoration: const InputDecoration(labelText: '周期'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('时间'),
                subtitle: Text(_tradeTime?.toLocal().toString() ?? '未设置'),
                trailing: TextButton(
                  onPressed: _pickTradeDateTime,
                  child: const Text('选择'),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('收藏'),
                value: _isFavorite,
                onChanged: (value) => setState(() => _isFavorite = value),
              ),
            ],
          ),
        );
      },
    );
  }
}
