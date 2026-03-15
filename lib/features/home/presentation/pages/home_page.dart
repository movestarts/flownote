import 'package:chart_flow/app/l10n/app_strings.dart';
import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/core/widgets/empty_state_widget.dart';
import 'package:chart_flow/features/notes/providers/note_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentNotesProvider);
    final favoriteAsync = ref.watch(favoriteNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(ref, 'appName')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickActions(ref, context),
          const SizedBox(height: 24),
          _sectionTitle(
            ref,
            context,
            AppStrings.of(ref, 'homeRecent'),
            onViewAll: () => context.push('/flow'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: recentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('${AppStrings.of(ref, 'loadFailed')}: $error')),
              data: (notes) {
                if (notes.isEmpty) {
                  return EmptyStateWidget(
                    title: AppStrings.of(ref, 'noNotesYet'),
                    subtitle: AppStrings.of(ref, 'noNotesYetHint'),
                    icon: Icons.photo_library_outlined,
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _NotePreviewCard(
                      note: note,
                      onTap: () => context.push(
                        '/flow',
                        extra: NoteQuery(tagIds: note.tagIds.take(1).toList()),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(
            ref,
            context,
            AppStrings.of(ref, 'homeFavorites'),
            onViewAll: () =>
                context.push('/flow', extra: const NoteQuery(favoriteOnly: true)),
          ),
          const SizedBox(height: 12),
          favoriteAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Text('${AppStrings.of(ref, 'loadFailed')}: $error'),
            data: (notes) {
              if (notes.isEmpty) {
                return EmptyStateWidget(
                  title: AppStrings.of(ref, 'noFavoritesYet'),
                  subtitle: AppStrings.of(ref, 'noFavoritesYetHint'),
                  icon: Icons.bookmark_outline,
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: notes
                    .take(10)
                    .map(
                      (n) => ActionChip(
                        label: Text(
                          n.tagNames.isEmpty
                              ? (n.title ?? AppStrings.of(ref, 'unnamed'))
                              : n.tagNames.first,
                        ),
                        onPressed: () => context.push(
                          '/flow',
                          extra: NoteQuery(tagIds: n.tagIds.take(1).toList()),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/quick-create'),
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(AppStrings.of(ref, 'create')),
      ),
    );
  }

  Widget _buildQuickActions(WidgetRef ref, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.bar_chart,
                title: AppStrings.of(ref, 'stats'),
                subtitle: AppStrings.of(ref, 'statsSubtitle'),
                onTap: () => context.push('/statistics'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.view_carousel,
                title: AppStrings.of(ref, 'flow'),
                subtitle: AppStrings.of(ref, 'flowSubtitle'),
                onTap: () => context.push('/flow'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.filter_alt_outlined,
                title: AppStrings.of(ref, 'filter'),
                subtitle: AppStrings.of(ref, 'filterSubtitle'),
                onTap: () => context.push('/filter'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.label_outline,
                title: AppStrings.of(ref, 'tags'),
                subtitle: AppStrings.of(ref, 'manageTagsHint'),
                onTap: () => context.push('/tags'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(
    WidgetRef ref,
    BuildContext context,
    String title, {
    required VoidCallback onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton(
          onPressed: onViewAll,
          child: Text(AppStrings.of(ref, 'viewAll')),
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) => AlertDialog(
          title: Text(AppStrings.of(ref, 'search')),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: AppStrings.of(ref, 'keyword'),
              prefixIcon: const Icon(Icons.search),
            ),
            onSubmitted: (value) {
              Navigator.pop(context);
              if (value.trim().isNotEmpty) {
                context.push('/flow', extra: NoteQuery(keyword: value.trim()));
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.of(ref, 'cancel')),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotePreviewCard extends ConsumerWidget {
  final Note note;
  final VoidCallback onTap;

  const _NotePreviewCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  note.isFavorite ? Icons.bookmark : Icons.photo,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Text(
              note.title ??
                  (note.tagNames.isEmpty
                      ? AppStrings.of(ref, 'unnamed')
                      : note.tagNames.first),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
