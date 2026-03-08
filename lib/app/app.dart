import 'package:chart_flow/app/router/app_router.dart';
import 'package:chart_flow/app/theme/app_theme.dart';
import 'package:chart_flow/app/l10n/app_strings.dart';
import 'package:chart_flow/shared/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChartFlowApp extends ConsumerWidget {
  const ChartFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppStrings.of(ref, 'appName'),
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('zh')],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
