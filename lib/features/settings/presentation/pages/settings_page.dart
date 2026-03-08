import 'package:chart_flow/app/l10n/app_strings.dart';
import 'package:chart_flow/core/constants/app_constants.dart';
import 'package:chart_flow/shared/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(ref, 'settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppStrings.of(ref, 'version')),
            subtitle: Text(AppConstants.appVersion),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppStrings.of(ref, 'language')),
            subtitle: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: 'en', label: Text(AppStrings.of(ref, 'english'))),
                ButtonSegment(
                    value: 'zh', label: Text(AppStrings.of(ref, 'chinese'))),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (selected) {
                final code = selected.first;
                localeNotifier.setLocale(Locale(code));
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(AppStrings.of(ref, 'tags')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tags'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bookmarks_outlined),
            title: Text(AppStrings.of(ref, 'savedFilters')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/saved-filters'),
          ),
        ],
      ),
    );
  }
}
