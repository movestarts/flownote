import 'package:chart_flow/features/statistics/domain/statistics.dart';
import 'package:chart_flow/features/statistics/providers/statistics_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('笔记分类统计'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '今日'),
            Tab(text: '本周'),
            Tab(text: '本月'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsView(todayStatisticsProvider),
          _buildStatsView(weekStatisticsProvider),
          _buildStatsView(thisMonthStatisticsProvider),
        ],
      ),
    );
  }

  Widget _buildStatsView(
      ProviderListenable<AsyncValue<NoteClassificationStats>> provider) {
    final statsAsync = ref.watch(provider);
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
      data: (stats) {
        if (stats.totalNotes == 0) {
          return const Center(child: Text('暂无笔记数据'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverview(stats),
              const SizedBox(height: 16),
              _buildCompleteness(stats),
              const SizedBox(height: 16),
              _buildTopCategoryCard(
                title: '标签 Top',
                items: stats.topTags,
                emptyText: '当前时间范围没有标签数据',
              ),
              const SizedBox(height: 16),
              _buildTopCategoryCard(
                title: '品种 Top',
                items: stats.topSymbols,
                emptyText: '当前时间范围没有品种数据',
              ),
              const SizedBox(height: 16),
              _buildTopCategoryCard(
                title: '周期 Top',
                items: stats.topTimeframes,
                emptyText: '当前时间范围没有周期数据',
              ),
              const SizedBox(height: 16),
              _buildWeekdayDistribution(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverview(NoteClassificationStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '概览',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _miniMetric('总笔记', stats.totalNotes),
                _miniMetric('收藏', stats.favorites),
                _miniMetric('有标签', stats.withTags),
                _miniMetric('有标题', stats.withTitle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(String label, int value) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blueGrey.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCompleteness(NoteClassificationStats stats) {
    final total = stats.totalNotes;
    double p(int value) => total == 0 ? 0 : value / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '笔记结构完整度',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ratioBar('带标题', stats.withTitle, total, p(stats.withTitle)),
            const SizedBox(height: 10),
            _ratioBar('带正文', stats.withContent, total, p(stats.withContent)),
            const SizedBox(height: 10),
            _ratioBar('带标签', stats.withTags, total, p(stats.withTags)),
            const SizedBox(height: 10),
            _ratioBar('带品种', stats.withSymbol, total, p(stats.withSymbol)),
            const SizedBox(height: 10),
            _ratioBar(
              '带周期',
              stats.withTimeframe,
              total,
              p(stats.withTimeframe),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratioBar(String label, int count, int total, double ratio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$count/$total (${(ratio * 100).toStringAsFixed(1)}%)'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: ratio),
      ],
    );
  }

  Widget _buildTopCategoryCard({
    required String title,
    required List<CategoryCount> items,
    required String emptyText,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(emptyText, style: TextStyle(color: Colors.grey[700]))
            else
              ...items.take(8).map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(item.label),
                      trailing: Text(
                        '${item.count}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayDistribution(NoteClassificationStats stats) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    final maxCount = stats.weekdayCounts.values.isEmpty
        ? 1
        : stats.weekdayCounts.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '周内记录分布',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(7, (index) {
              final weekday = index + 1;
              final count = stats.weekdayCounts[weekday] ?? 0;
              final ratio = count / maxCount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 20, child: Text(names[index])),
                    Expanded(
                      child: LinearProgressIndicator(value: ratio),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 28, child: Text('$count')),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
