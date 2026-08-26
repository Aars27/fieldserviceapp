import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';

final _dashboardUseCaseProvider = Provider<GetDashboardStatsUseCase>((ref) {
  return GetDashboardStatsUseCase(ref.read(jobRepositoryProvider));
});

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardStats>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() => ref.read(_dashboardUseCaseProvider).call();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(_dashboardUseCaseProvider).call());
  }
}
