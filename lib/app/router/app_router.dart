import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chart_flow/features/home/presentation/pages/home_page.dart';
import 'package:chart_flow/features/notes/presentation/pages/create_note_page.dart';
import 'package:chart_flow/features/notes/presentation/pages/quick_create_note_page.dart';
import 'package:chart_flow/features/notes/presentation/pages/edit_note_page.dart';
import 'package:chart_flow/features/notes/presentation/pages/flow_page.dart';
import 'package:chart_flow/features/filters/presentation/pages/filter_page.dart';
import 'package:chart_flow/features/filters/presentation/pages/saved_filters_page.dart';
import 'package:chart_flow/features/tags/presentation/pages/tags_page.dart';
import 'package:chart_flow/features/settings/presentation/pages/settings_page.dart';
import 'package:chart_flow/features/statistics/presentation/pages/statistics_page.dart';
import 'package:chart_flow/core/domain/entities.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        builder: (context, state) => const CreateNotePage(),
      ),
      GoRoute(
        path: '/quick-create',
        name: 'quickCreate',
        builder: (context, state) => const QuickCreateNotePage(),
      ),
      GoRoute(
        path: '/note/:id/edit',
        name: 'edit',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EditNotePage(noteId: id);
        },
      ),
      GoRoute(
        path: '/flow',
        name: 'flow',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is NoteQuery) {
            return FlowPage(query: extra);
          }
          return const FlowPage();
        },
      ),
      GoRoute(
        path: '/filter',
        name: 'filter',
        builder: (context, state) => const FilterPage(),
      ),
      GoRoute(
        path: '/saved-filters',
        name: 'savedFilters',
        builder: (context, state) => const SavedFiltersPage(),
      ),
      GoRoute(
        path: '/tags',
        name: 'tags',
        builder: (context, state) => const TagsPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsPage(),
      ),
    ],
  );
});
