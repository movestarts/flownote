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
        title: const Text('Chart Flow'),
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
          _buildQuickActions(context),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Recent Notes',
              onViewAll: () => context.push('/flow')),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: recentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Load failed: $error')),
              data: (notes) {
                if (notes.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No notes yet',
                    subtitle: 'Tap "Create" to import your first image.',
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
                      onTap: () => context.push('/flow',
                          extra:
                              NoteQuery(tagIds: note.tagIds.take(1).toList())),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(
            context,
            'Favorites',
            onViewAll: () => context.push('/flow',
                extra: const NoteQuery(favoriteOnly: true)),
          ),
          const SizedBox(height: 12),
          favoriteAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Load failed: $error'),
            data: (notes) {
              if (notes.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No favorites yet',
                  subtitle: 'Bookmark notes in Flow to collect key samples.',
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
                        label: Text(n.tagNames.isEmpty
                            ? (n.title ?? '未命名')
                            : n.tagNames.first),
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
        onPressed: () => context.push('/create'),
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Create'),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.view_carousel,
                title: 'Flow',
                subtitle: 'Swipe notes vertically',
                onTap: () => context.push('/flow'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.filter_alt_outlined,
                title: 'Filter',
                subtitle: 'Combine conditions',
                onTap: () => context.push('/filter'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _QuickActionCard(
          icon: Icons.label_outline,
          title: 'Tags',
          subtitle: 'Manage tags before creating notes',
          onTap: () => context.push('/tags'),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title,
      {required VoidCallback onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Keyword',
            prefixIcon: Icon(Icons.search),
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
            child: const Text('Cancel'),
          ),
        ],
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

class _NotePreviewCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NotePreviewCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  (note.tagNames.isEmpty ? '未命名' : note.tagNames.first),
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
