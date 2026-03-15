import 'package:chart_flow/app/l10n/app_strings.dart';
import 'dart:io';

import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/core/widgets/image_picker_card.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';
import 'package:chart_flow/features/tags/providers/tag_providers.dart';
import 'package:chart_flow/shared/providers/recent_usage_providers.dart';
import 'package:chart_flow/shared/providers/services_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CreateNotePage extends ConsumerStatefulWidget {
  const CreateNotePage({super.key});

  @override
  ConsumerState<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends ConsumerState<CreateNotePage> {
  static const _recentTagField = 'recent_tag_id';
  static const _recentSymbolField = 'recent_symbol';
  static const _recentTimeframeField = 'recent_timeframe';

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _symbolController = TextEditingController();
  final _timeframeController = TextEditingController();
  final _newTagController = TextEditingController();

  String? _sourceImagePath;
  DateTime? _tradeTime;
  bool _isFavorite = false;
  bool _saving = false;
  bool _loadedDefaults = false;
  Set<String> _selectedTagIds = <String>{};

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _symbolController.dispose();
    _timeframeController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentDefaults() async {
    if (_loadedDefaults) return;
    _loadedDefaults = true;

    final recentRepo = ref.read(recentUsageRepositoryProvider);
    final symbolValues =
        await recentRepo.getRecentFieldValues(_recentSymbolField, limit: 1);
    final timeframeValues =
        await recentRepo.getRecentFieldValues(_recentTimeframeField, limit: 1);
    final tagIds =
        await recentRepo.getRecentFieldValues(_recentTagField, limit: 5);

    if (!mounted) return;
    setState(() {
      _symbolController.text = symbolValues.isEmpty ? '' : symbolValues.first;
      _timeframeController.text =
          timeframeValues.isEmpty ? '' : timeframeValues.first;
      _selectedTagIds = tagIds.toSet();
    });
  }

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (image == null) return;
    setState(() {
      _sourceImagePath = image.path;
    });
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
    setState(() {
      _selectedTagIds.add(tag.id);
      _newTagController.clear();
    });
  }

  Future<void> _openTagManager() async {
    await context.push('/tags');
    ref.invalidate(allTagsProvider);
  }

  Future<void> _saveNote({required bool keepEditing}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceImagePath == null) {
      _showMessage(AppStrings.of(ref, 'selectImageFirst'));
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final noteRepository = ref.read(noteRepositoryProvider);
      final fileService = ref.read(localFileServiceProvider);
      final recentRepo = ref.read(recentUsageRepositoryProvider);

      final imagePath =
          await fileService.copyImageToAppDirectory(_sourceImagePath!);
      final now = DateTime.now();
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final symbol = _symbolController.text.trim();
      final timeframe = _timeframeController.text.trim();

      final note = Note(
        id: _uuid.v4(),
        imagePath: imagePath,
        title: title.isEmpty ? null : title,
        content: content.isEmpty ? null : content,
        symbol: symbol.isEmpty ? null : symbol,
        timeframe: timeframe.isEmpty ? null : timeframe,
        tradeTime: _tradeTime,
        isFavorite: _isFavorite,
        createdAt: now,
        updatedAt: now,
        tagIds: _selectedTagIds.toList(),
      );

      await noteRepository.createNote(note);

      if (symbol.isNotEmpty) {
        await recentRepo.recordUsage(_recentSymbolField, symbol);
      }
      if (timeframe.isNotEmpty) {
        await recentRepo.recordUsage(_recentTimeframeField, timeframe);
      }
      for (final tagId in _selectedTagIds) {
        await recentRepo.recordUsage(_recentTagField, tagId);
      }

      ref.read(notesRefreshTickProvider.notifier).state++;

      if (!mounted) return;
      _showMessage(AppStrings.of(ref, 'saveSuccess'));
      if (keepEditing) {
        setState(() {
          _sourceImagePath = null;
          _titleController.clear();
          _contentController.clear();
          _tradeTime = null;
          _isFavorite = false;
        });
      } else {
        context.pop();
      }
    } catch (e) {
      _showMessage('${AppStrings.of(ref, 'saveFailed')}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(allTagsProvider);
    _loadRecentDefaults();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(ref, 'createNote')),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _saveNote(keepEditing: true),
            child: Text(AppStrings.of(ref, 'saveAndNext')),
          ),
          TextButton(
            onPressed: _saving ? null : () => _saveNote(keepEditing: false),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppStrings.of(ref, 'save')),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ImagePickerCard(
              imagePath: _sourceImagePath,
              onTap: _pickImage,
              height: 220,
              placeholder:
                  Center(child: Text(AppStrings.of(ref, 'importImage'))),
            ),
            const SizedBox(height: 16),
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
                  Text('${AppStrings.of(ref, "loadTagsFailed")}: $error'),
              data: (tags) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.of(ref, 'tags'),
                          style: Theme.of(context).textTheme.titleSmall),
                      TextButton.icon(
                        onPressed: _openTagManager,
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: Text(AppStrings.of(ref, 'manageTags')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                              hintText: AppStrings.of(ref, 'createNewTag')),
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
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.of(ref, 'tradeTime')),
              subtitle:
                  Text(_tradeTime?.toLocal().toString() ?? AppStrings.of(ref, 'notSet')),
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
            if (_sourceImagePath != null &&
                !File(_sourceImagePath!).existsSync())
              const Text(
                'Selected image is no longer accessible, please reselect.',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
