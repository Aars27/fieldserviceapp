import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/job_details/presentation/screens/job_details_screen.dart';
import '../../features/jobs/domain/entities/job_status.dart';
import '../../features/jobs/domain/repositories/job_repository.dart';
import '../../features/jobs/presentation/screens/jobs_list_screen.dart';
import '../widgets/main_scaffold.dart';

/// Route name constants so screens never hardcode path strings.
class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const dashboard = '/dashboard';
  static const jobs = '/jobs';
  static const jobDetails = '/jobs/:id';
}

GoRouter buildRouter(ProviderContainer container) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) async {
      final authUser = await container.read(authNotifierProvider.future);
      final isLoggedIn = authUser != null;
      final goingToLogin = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !goingToLogin) return AppRoutes.login;
      if (isLoggedIn && goingToLogin) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.jobs,
            builder: (context, state) {
              final statusParam = state.uri.queryParameters['status'];
              final overdueParam = state.uri.queryParameters['overdue'] == 'true';

              Set<JobStatus> statuses = {};
              if (statusParam != null && statusParam.isNotEmpty) {
                statuses = statusParam
                    .split(',')
                    .map((s) => JobStatus.fromString(s.trim()))
                    .toSet();
              }

              final filter = (state.extra as JobsFilter?) ??
                  (statusParam != null || overdueParam
                      ? JobsFilter(
                          statuses: statuses,
                          overdueOnly: overdueParam,
                        )
                      : null);

              return JobsListScreen(initialFilter: filter);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.jobDetails,
        builder: (context, state) => JobDetailsScreen(
          jobId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
}
