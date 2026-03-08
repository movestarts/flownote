import 'package:chart_flow/core/domain/entities.dart';
import 'package:chart_flow/features/filters/providers/filter_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FilterPage extends ConsumerStatefulWidget {
  const FilterPage({super.key});

  @override
  ConsumerState<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends ConsumerState<FilterPage> {
  final _keywordController = TextEditingController();

  final Set<String> _selectedTagIds = <String>{};
  final Set<String> _selectedSymbols = <String>{};
  final Set<String> _selectedTimeframes = <String>{};

  bool _favoriteOnly = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  NoteQuery get _query => NoteQuery(
        tagIds: _selectedTagIds.toList(),
        symbols: _selectedSymbols.toList(),
        timeframes: _selectedTimeframes.toList(),
        favoriteOnly: _favoriteOnly ? true : null,
        startTime: _startDate,
        endTime: _endDate == null
            ? null
            : DateTime(
                _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59),
        keyword: _keywordController.text.trim().isEmpty
            ? null
            : _keywordController.text.trim(),
      );

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null) return;
    setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null) return;
    setState(() => _endDate = date);
  }

  void _clearAll() {
    setState(() {
      _selectedTagIds.clear();
      _selectedSymbols.clear();
      _selectedTimeframes.clear();
      _favoriteOnly = false;
      _startDate = null;
      _endDate = null;
      _keywordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(filterOptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('筛选'),
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: const Text('清空'),
          ),
          TextButton(
            onPressed: () => context.push('/flow', extra: _query),
            child: const Text('应用'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => context.push('/saved-filters'),
          ),
        ],
      ),
      body: optionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
        data: (options) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _keywordController,
                decoration: const InputDecoration(
                  labelText: '关键词（标题/备注）',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              _buildTagSection(options),
              const SizedBox(height: 16),
              _buildStringSetSection(
                title: '品种',
                values: options.symbols,
                selected: _selectedSymbols,
              ),
              const SizedBox(height: 16),
              _buildStringSetSection(
                title: '周期',
                values: options.timeframes,
                selected: _selectedTimeframes,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _favoriteOnly,
                title: const Text('仅收藏'),
                onChanged: (value) => setState(() => _favoriteOnly = value),
              ),
              const SizedBox(height: 8),
              _buildDateSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTagSection(FilterOptions options) {
    return _FilterCard(
      title: '标签',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.tags.map((tag) {
          return FilterChip(
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
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStringSetSection({
    required String title,
    required List<String> values,
    required Set<String> selected,
  }) {
    return _FilterCard(
      title: title,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: values.map((value) {
          return FilterChip(
            selected: selected.contains(value),
            label: Text(value),
            onSelected: (isSelected) {
              setState(() {
                if (isSelected) {
                  selected.add(value);
                } else {
                  selected.remove(value);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSection() {
    return _FilterCard(
      title: '时间范围',
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _pickStartDate,
              child: Text(_startDate == null ? '开始日期' : _fmtDate(_startDate!)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _pickEndDate,
              child: Text(_endDate == null ? '结束日期' : _fmtDate(_endDate!)),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}

class _FilterCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
