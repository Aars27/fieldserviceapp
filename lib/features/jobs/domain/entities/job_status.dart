enum JobStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  /// Valid forward transitions. Skipping states (pending → completed) and
  /// reversals are intentionally excluded — the server enforces this too,
  /// but we validate client-side to give instant feedback.
  static const validTransitions = <JobStatus, Set<JobStatus>>{
    JobStatus.pending: {JobStatus.inProgress, JobStatus.cancelled},
    JobStatus.inProgress: {JobStatus.completed, JobStatus.cancelled},
    JobStatus.completed: {},
    JobStatus.cancelled: {},
  };

  bool canTransitionTo(JobStatus next) =>
      validTransitions[this]?.contains(next) ?? false;

  String get label => switch (this) {
        JobStatus.pending => 'Pending',
        JobStatus.inProgress => 'In Progress',
        JobStatus.completed => 'Completed',
        JobStatus.cancelled => 'Cancelled',
      };

  static JobStatus fromString(String value) => switch (value) {
        'pending' => JobStatus.pending,
        'in_progress' => JobStatus.inProgress,
        'completed' => JobStatus.completed,
        'cancelled' => JobStatus.cancelled,
        _ => JobStatus.pending,
      };

  String get apiValue => switch (this) {
        JobStatus.pending => 'pending',
        JobStatus.inProgress => 'in_progress',
        JobStatus.completed => 'completed',
        JobStatus.cancelled => 'cancelled',
      };
}
