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

  String? _sourceImagePath;
  bool _saving = false;

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (image == null) return;
    setState(() {
      _sourceImagePath = image.path;
    });
  }

  Future<void> _saveAndContinue() async {
    if (_sourceImagePath == null) {
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

      final savedPath =
          await fileService.copyImageToAppDirectory(_sourceImagePath!);

      final note = Note(
        id: _uuid.v4(),
        imagePath: savedPath,
        createdAt: now,
        updatedAt: now,
      );

      await noteRepository.createNote(note);
      ref.read(notesRefreshTickProvider.notifier).state++;

      if (!mounted) return;

      final shouldEdit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.of(ref, 'saveSuccess')),
          content: Text(AppStrings.of(ref, 'quickCreateHint')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.of(ref, 'later')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.of(ref, 'editNow')),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (shouldEdit == true) {
        context.go('/note/${note.id}/edit');
      } else {
        setState(() {
          _sourceImagePath = null;
        });
        _showMessage(AppStrings.of(ref, 'saveSuccess'));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(ref, 'quickCreate')),
        actions: [
          if (_sourceImagePath != null)
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
            ImagePickerCard(
              imagePath: _sourceImagePath,
              onTap: _pickImage,
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
                      AppStrings.of(ref, 'quickCreatePickImage'),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.of(ref, 'quickCreateHint'),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
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
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${AppStrings.of(ref, 'quickCreateTip1')}\n'
                    '• ${AppStrings.of(ref, 'quickCreateTip2')}\n'
                    '• ${AppStrings.of(ref, 'quickCreateTip3')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (_sourceImagePath != null) ...[
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveAndContinue,
                icon: const Icon(Icons.save),
                label: Text(AppStrings.of(ref, 'saveAndContinue')),
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
            if (_sourceImagePath != null &&
                !File(_sourceImagePath!).existsSync())
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Selected image is no longer accessible.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
