import '../../../../core/errors/result.dart';
import '../entities/job.dart';
import '../repositories/job_repository.dart';

class GetJobsUseCase {
  final JobRepository _repo;

  GetJobsUseCase(this._repo);

  Future<Result<List<Job>>> call({
    required int page,
    required int limit,
    required JobsFilter filter,
    Object? cancelToken,
  }) {
    return _repo.getJobs(
      page: page,
      limit: limit,
      filter: filter,
      cancelToken: cancelToken,
    );
  }
}
