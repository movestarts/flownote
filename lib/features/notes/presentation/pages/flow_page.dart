import 'dart:io';

import 'package:chart_flow/app/l10n/app_strings.dart';
import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/core/widgets/empty_state_widget.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FlowPage extends ConsumerStatefulWidget {
  final NoteQuery query;

  const FlowPage({
    super.key,
    NoteQuery? query,
  }) : query = query ?? const NoteQuery();

  @override
  ConsumerState<FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends ConsumerState<FlowPage> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(Note note) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.toggleFavorite(note.id);
    ref.read(notesRefreshTickProvider.notifier).state++;
  }

  Future<void> _deleteNote(Note note) async {
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

    if (shouldDelete != true || !mounted) return;

    final repository = ref.read(noteRepositoryProvider);
    await repository.deleteNote(note.id);
    ref.read(notesRefreshTickProvider.notifier).state++;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(ref, 'deleted'))),
    );
  }

  void _backToPreviousOrHome() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesByQueryProvider(widget.query));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _backToPreviousOrHome,
        ),
        title: Text(
          widget.query.isEmpty
              ? AppStrings.of(ref, 'flow')
              : AppStrings.of(ref, 'filteredFlow'),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => context.push('/filter'),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            '${AppStrings.of(ref, 'loadFailed')}: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyStateWidget(
              title: AppStrings.of(ref, 'noNotesFound'),
              subtitle: AppStrings.of(ref, 'noNotesFoundHint'),
              icon: Icons.image_not_supported_outlined,
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: (value) => setState(() => _index = value),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return _FlowCard(
                    note: note,
                    onToggleFavorite: () => _toggleFavorite(note),
                    onEdit: () => context.push('/note/${note.id}/edit'),
                    onDelete: () => _deleteNote(note),
                  );
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_index + 1}/${notes.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FlowCard extends ConsumerWidget {
  final Note note;
  final VoidCallback onToggleFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlowCard({
    required this.note,
    required this.onToggleFavorite,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(note.imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
            );
          },
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0.55, 1],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _quickActionButton(
                icon: note.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                label: note.isFavorite
                    ? AppStrings.of(ref, 'favorite')
                    : AppStrings.of(ref, 'favorite'),
                onTap: onToggleFavorite,
              ),
              const SizedBox(height: 8),
              _quickActionButton(
                icon: Icons.edit_outlined,
                label: AppStrings.of(ref, 'editNote'),
                onTap: onEdit,
              ),
              const SizedBox(height: 8),
              _quickActionButton(
                icon: Icons.delete_outline,
                label: AppStrings.of(ref, 'delete'),
                onTap: onDelete,
                foregroundColor: Colors.red.shade100,
                borderColor: Colors.red.shade200.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...note.tagNames.map(_metaChip),
                  if (note.symbol != null) _metaChip(note.symbol!),
                  if (note.timeframe != null) _metaChip(note.timeframe!),
                ],
              ),
              if (note.title != null && note.title!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  note.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (note.content != null && note.content!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  note.content!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                note.tradeTime
                        ?.toIso8601String()
                        .replaceFirst('T', ' ')
                        .substring(0, 16) ??
                    note.createdAt
                        .toIso8601String()
                        .replaceFirst('T', ' ')
                        .substring(0, 16),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color foregroundColor = Colors.white,
    Color borderColor = Colors.white24,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
