import 'package:chart_flow/shared/providers/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _values = {
    'en': {
      'appName': 'Chart Flow',
      'settings': 'Settings',
      'version': 'Version',
      'tags': 'Tags',
      'savedFilters': 'Saved Filters',
      'language': 'Language',
      'english': 'English',
      'chinese': 'Chinese',
      'homeRecent': 'Recent Notes',
      'homeFavorites': 'Favorites',
      'viewAll': 'View All',
      'create': 'Create',
      'flow': 'Flow',
      'filter': 'Filter',
      'manageTagsHint': 'Manage tags before creating notes',
      'createNote': 'Create Note',
      'save': 'Save',
      'saveAndNext': 'Save & Next',
      'title': 'Title',
      'content': 'Content',
      'symbol': 'Symbol',
      'timeframe': 'Timeframe',
      'tradeTime': 'Trade Time',
      'select': 'Select',
      'favorite': 'Favorite',
      'manageTags': 'Manage Tags',
      'importImage': 'Tap to import image',
      'loadTagsFailed': 'Load tags failed',
      'createNewTag': 'Create new tag',
    },
    'zh': {
      'appName': '图流复盘',
      'settings': '设置',
      'version': '版本',
      'tags': '标签',
      'savedFilters': '已保存筛选',
      'language': '语言',
      'english': '英文',
      'chinese': '中文',
      'homeRecent': '最近笔记',
      'homeFavorites': '收藏',
      'viewAll': '查看全部',
      'create': '创建',
      'flow': '流览',
      'filter': '筛选',
      'manageTagsHint': '先管理标签再创建笔记',
      'createNote': '创建笔记',
      'save': '保存',
      'saveAndNext': '保存并继续',
      'title': '标题',
      'content': '备注',
      'symbol': '品种',
      'timeframe': '周期',
      'tradeTime': '时间',
      'select': '选择',
      'favorite': '收藏',
      'manageTags': '管理标签',
      'importImage': '点击导入图片',
      'loadTagsFailed': '标签加载失败',
      'createNewTag': '新建标签',
    },
  };

  static String of(WidgetRef ref, String key) {
    final code = ref.watch(localeProvider).languageCode;
    return _values[code]?[key] ?? _values['en']![key] ?? key;
  }
}
