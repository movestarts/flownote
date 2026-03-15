import 'dart:io';

import 'package:chart_flow/app/l10n/app_strings.dart';
import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/core/widgets/image_picker_card.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';
import 'package:chart_flow/shared/providers/services_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class QuickCreateNotePage extends ConsumerStatefulWidget {
  const QuickCreateNotePage({super.key});

  @override
  ConsumerState<QuickCreateNotePage> createState() =>
      _QuickCreateNotePageState();
}

class _QuickCreateNotePageState extends ConsumerState<QuickCreateNotePage> {
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  List<String> _sourceImagePaths = <String>[];
  bool _saving = false;

  String _normalizeImagePath(String path) {
    if (!path.startsWith('file://')) return path;
    try {
      return Uri.parse(path).toFilePath(windows: Platform.isWindows);
    } catch (_) {
      return path;
    }
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 92);
    if (images.isEmpty) return;

    setState(() {
      final paths = _sourceImagePaths.toSet();
      for (final image in images) {
        paths.add(_normalizeImagePath(image.path));
      }
      _sourceImagePaths = paths.toList();
    });
  }

  Future<void> _saveAndContinue() async {
    if (_sourceImagePaths.isEmpty) {
      _showMessage(AppStrings.of(ref, 'selectImageFirst'));
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final fileService = ref.read(localFileServiceProvider);
      final noteRepository = ref.read(noteRepositoryProvider);
      final now = DateTime.now();
      final failedPaths = <String>[];
      final savedNoteIds = <String>[];
      String? firstSavedNoteId;
      var savedCount = 0;

      for (final sourcePath in _sourceImagePaths) {
        String? savedPath;
        try {
          savedPath = await fileService.copyImageToAppDirectory(sourcePath);
          final note = Note(
            id: _uuid.v4(),
            imagePath: savedPath,
            createdAt: now,
            updatedAt: now,
          );
          await noteRepository.createNote(note);

          firstSavedNoteId ??= note.id;
          savedNoteIds.add(note.id);
          savedCount++;
        } catch (_) {
          if (savedPath != null) {
            try {
              await fileService.deleteImage(savedPath);
            } catch (_) {
              // Best-effort cleanup: keep batch flow going even if file delete fails.
            }
          }
          failedPaths.add(sourcePath);
        }
      }

      if (savedCount > 0) {
        ref.read(notesRefreshTickProvider.notifier).state++;
      }

      if (!mounted) return;

      if (savedCount == 0) {
        _showMessage(AppStrings.of(ref, 'quickCreateNoValidImage'));
        return;
      }

      final hasPartialFailure = failedPaths.isNotEmpty;
      final shouldEdit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppStrings.of(ref, 'saveSuccess')),
              content: Text(
                '$savedCount ${AppStrings.of(ref, 'batchImported')}.\n'
                '${hasPartialFailure ? '${failedPaths.length} ${AppStrings.of(ref, 'batchImportFailedAndRetained')}' : AppStrings.of(ref, 'quickCreateHint')}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppStrings.of(ref, 'later')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    savedCount == 1
                        ? AppStrings.of(ref, 'editNow')
                        : AppStrings.of(ref, 'editFirst'),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (!mounted) return;

      if (shouldEdit && firstSavedNoteId != null) {
        context.go('/note/$firstSavedNoteId/edit', extra: savedNoteIds);
      } else {
        setState(() {
          _sourceImagePaths = failedPaths;
        });
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invalidCount =
        _sourceImagePaths.where((path) => !File(path).existsSync()).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(ref, 'quickCreate')),
        actions: [
          if (_sourceImagePaths.isNotEmpty)
            TextButton(
              onPressed: _saving ? null : _saveAndContinue,
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_sourceImagePaths.isEmpty)
              ImagePickerCard(
                imagePath: null,
                onTap: _pickImages,
                height: 300,
                placeholder: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.of(ref, 'quickCreatePickImages'),
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.of(ref, 'quickCreateHint'),
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppStrings.of(ref, 'selectedCountPrefix')} ${_sourceImagePaths.length}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      TextButton.icon(
                        onPressed: _saving ? null : _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(AppStrings.of(ref, 'addMoreImages')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sourceImagePaths.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final imagePath = _sourceImagePaths[index];
                        final exists = File(imagePath).existsSync();

                        return Stack(
                          children: [
                            Container(
                              width: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: exists
                                      ? Theme.of(context).dividerColor
                                      : Colors.red.withValues(alpha: 0.6),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: exists
                                    ? Image.file(
                                        File(imagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Theme.of(context).cardColor,
                                          alignment: Alignment.center,
                                          child: Text(
                                            AppStrings.of(
                                              ref,
                                              'imageNotAccessible',
                                            ),
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Theme.of(context).cardColor,
                                        alignment: Alignment.center,
                                        child: Text(
                                          AppStrings.of(
                                            ref,
                                            'imageNotAccessible',
                                          ),
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _saving
                                      ? null
                                      : () {
                                          setState(() {
                                            _sourceImagePaths.removeAt(index);
                                          });
                                        },
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.of(ref, 'quickCreateMode'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '- ${AppStrings.of(ref, 'quickCreateTip1')}\n'
                    '- ${AppStrings.of(ref, 'quickCreateTip2')}\n'
                    '- ${AppStrings.of(ref, 'quickCreateTip3')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (_sourceImagePaths.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveAndContinue,
                icon: const Icon(Icons.save),
                label: Text(
                  _sourceImagePaths.length == 1
                      ? AppStrings.of(ref, 'saveAndContinue')
                      : AppStrings.of(ref, 'batchSaveAndContinue'),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  context.push('/create');
                },
                icon: const Icon(Icons.edit_note),
                label: Text(AppStrings.of(ref, 'goDetailedMode')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            if (invalidCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '$invalidCount ${AppStrings.of(ref, 'imagesInaccessibleSuffix')}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
