import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/job.dart';
import '../entities/job_status.dart';
import '../repositories/job_repository.dart';

class UpdateJobStatusUseCase {
  final JobRepository _repo;

  UpdateJobStatusUseCase(this._repo);

  Future<Result<Job>> call(String jobId, JobStatus currentStatus, JobStatus newStatus) {
    if (!currentStatus.canTransitionTo(newStatus)) {
      return Future.value(
        Err(ValidationFailure(
          'Cannot move from ${currentStatus.label} to ${newStatus.label}.',
        )),
      );
    }
    return _repo.updateJobStatus(jobId, newStatus);
  }
}
