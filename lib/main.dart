import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/jobs/data/models/job_model.dart';
import 'features/notifications/notification_service.dart';
import 'features/sync/data/sync_queue.dart';
import 'features/sync/domain/entities/pending_sync_operation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive
    ..registerAdapter(HiveJobStatusAdapter())
    ..registerAdapter(HiveJobPriorityAdapter())
    ..registerAdapter(StatusEventModelAdapter())
    ..registerAdapter(AttachmentModelAdapter())
    ..registerAdapter(JobModelAdapter())
    ..registerAdapter(SyncOperationTypeAdapter())
    ..registerAdapter(PendingSyncOperationAdapter());

  await Future.wait([
    Hive.openBox<JobModel>(AppConstants.jobsBoxName),
    Hive.openBox<PendingSyncOperation>(AppConstants.pendingSyncBoxName),
    Hive.openBox<PendingSyncOperation>(SyncQueue.deadLetterBoxName),
  ]);

  final prefs = await SharedPreferences.getInstance();

  await NotificationService.init();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: FieldServiceApp(router: buildRouter(container)),
    ),
  );
}

class FieldServiceApp extends StatelessWidget {
  final GoRouter router;

  const FieldServiceApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeNotifierProvider);
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
