import 'package:chart_flow/app/l10n/app_strings.dart';
import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';
import 'package:chart_flow/features/tags/providers/tag_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class EditNotePage extends ConsumerStatefulWidget {
  final String noteId;
  final List<String> batchNoteIds;

  const EditNotePage({
    super.key,
    required this.noteId,
    this.batchNoteIds = const <String>[],
  });

  @override
  ConsumerState<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends ConsumerState<EditNotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _symbolController = TextEditingController();
  final _timeframeController = TextEditingController();
  final _newTagController = TextEditingController();
  final _uuid = const Uuid();

  DateTime? _tradeTime;
  bool _isFavorite = false;
  Set<String> _selectedTagIds = <String>{};
  Note? _loadedNote;
  bool _saving = false;
  late final Future<Note?> _noteFuture;

  @override
  void initState() {
    super.initState();
    _noteFuture = ref.read(noteRepositoryProvider).getNoteById(widget.noteId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _symbolController.dispose();
    _timeframeController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _createTag() async {
    final name = _newTagController.text.trim();
    if (name.isEmpty) return;

    final tagRepository = ref.read(tagRepositoryProvider);
    final now = DateTime.now();
    final existing = await tagRepository.getTagByName(name);

    final tag = existing ??
        Tag(
          id: _uuid.v4(),
          name: name,
          createdAt: now,
          updatedAt: now,
        );

    if (existing == null) {
      await tagRepository.createTag(tag);
    }

    ref.invalidate(allTagsProvider);
    if (!mounted) return;
    setState(() {
      _selectedTagIds.add(tag.id);
      _newTagController.clear();
    });
  }

  Future<void> _openTagManager() async {
    await context.push('/tags');
    ref.invalidate(allTagsProvider);
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
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _save() async {
    final note = _loadedNote;
    if (note == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(noteRepositoryProvider);
      final tagRepo = ref.read(tagRepositoryProvider);
      final validTagIds =
          (await tagRepo.getAllTags()).map((tag) => tag.id).toSet();
      final selectedTagIds =
          _selectedTagIds.where((id) => validTagIds.contains(id)).toList();

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
          tagIds: selectedTagIds,
          updatedAt: DateTime.now(),
        ),
      );

      final batchTargetIds =
          widget.batchNoteIds.where((id) => id != note.id).toSet().toList();
      if (batchTargetIds.isNotEmpty) {
        for (final batchNoteId in batchTargetIds) {
          final batchNote = await repo.getNoteById(batchNoteId);
          if (batchNote == null) continue;
          await repo.updateNote(
            batchNote.copyWith(
              tagIds: selectedTagIds,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      ref.read(notesRefreshTickProvider.notifier).state++;
      if (!mounted) return;
      _exitAfterAction();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of(ref, 'saveFailed')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(ref, 'deleteNoteTitle')),
        content: Text(AppStrings.of(ref, 'deleteNoteHint')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.of(ref, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.of(ref, 'delete')),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _saving = true);
    try {
      await ref.read(noteRepositoryProvider).deleteNote(widget.noteId);
      ref.read(notesRefreshTickProvider.notifier).state++;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(ref, 'deleted'))),
      );
      _exitAfterAction();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _exitAfterAction() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/flow');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Note?>(
      future: _noteFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final note = snapshot.data;
        if (note == null) {
          return Scaffold(
            body: Center(child: Text(AppStrings.of(ref, 'noteNotFound'))),
          );
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
            title: Text(AppStrings.of(ref, 'editNote')),
            actions: [
              TextButton.icon(
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  AppStrings.of(ref, 'delete'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: _saving ? null : _save,
                child: Text(AppStrings.of(ref, 'save')),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration:
                    InputDecoration(labelText: AppStrings.of(ref, 'title')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration:
                    InputDecoration(labelText: AppStrings.of(ref, 'content')),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              tagsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    Text('${AppStrings.of(ref, 'tagLoadFailed')}: $error'),
                data: (tags) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.of(ref, 'tags'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        TextButton.icon(
                          onPressed: _openTagManager,
                          icon: const Icon(Icons.settings_outlined, size: 16),
                          label: Text(AppStrings.of(ref, 'manageTags')),
                        ),
                      ],
                    ),
                    if (tags.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          AppStrings.of(ref, 'manageTagsHint'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    Wrap(
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newTagController,
                            decoration: InputDecoration(
                              hintText: AppStrings.of(ref, 'createNewTag'),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _createTag,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _symbolController,
                decoration:
                    InputDecoration(labelText: AppStrings.of(ref, 'symbol')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeframeController,
                decoration:
                    InputDecoration(labelText: AppStrings.of(ref, 'timeframe')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.of(ref, 'tradeTime')),
                subtitle: Text(_tradeTime?.toLocal().toString() ??
                    AppStrings.of(ref, 'notSet')),
                trailing: TextButton(
                  onPressed: _pickTradeDateTime,
                  child: Text(AppStrings.of(ref, 'select')),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.of(ref, 'favorite')),
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
