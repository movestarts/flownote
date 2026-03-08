import 'dart:async';

import 'package:chart_flow/app/app.dart';
import 'package:chart_flow/shared/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  runZonedGuarded(() async {
    final container = ProviderContainer();
    try {
      await container.read(databaseProvider).initialize();
    } catch (e, st) {
      runApp(_FatalBootApp(error: e, stackTrace: st));
      return;
    }

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const ChartFlowApp(),
      ),
    );
  }, (error, stackTrace) {
    runApp(_FatalBootApp(error: error, stackTrace: stackTrace));
  });
}

class _FatalBootApp extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const _FatalBootApp({
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('启动失败')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              '应用启动时发生异常：\n$error\n\n$stackTrace',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}
