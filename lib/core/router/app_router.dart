import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/job_details/presentation/screens/job_details_screen.dart';
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
      final authState = container.read(authNotifierProvider);
      final isLoggedIn = authState.valueOrNull != null;
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
            builder: (context, state) => const JobsListScreen(),
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
