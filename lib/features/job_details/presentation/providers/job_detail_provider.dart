import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/domain/entities/job_status.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';

final jobDetailProvider =
    AsyncNotifierProviderFamily<JobDetailNotifier, Job, String>(JobDetailNotifier.new);

class JobDetailNotifier extends FamilyAsyncNotifier<Job, String> {
  @override
  Future<Job> build(String arg) async {
    final result = await ref.read(jobRepositoryProvider).getJob(arg);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw Exception(failure.message),
    };
  }

  Future<String?> updateStatus(JobStatus newStatus) async {
    final current = state.valueOrNull;
    if (current == null) return 'Job not loaded.';

    final result = await ref
        .read(updateJobStatusUseCaseProvider)
        .call(current.id, current.status, newStatus);

    switch (result) {
      case Ok(:final value):
        state = AsyncData(value);
        return null;
      case Err(:final failure):
        return failure.message;
    }
  }

  Future<String?> uploadAttachment(File file, void Function(double) onProgress) async {
    final job = state.valueOrNull;
    if (job == null) return 'Job not loaded.';

    final result = await ref.read(jobRepositoryProvider).addAttachment(
          job.id,
          file,
          onProgress: (sent, total) => onProgress(sent / total),
        );

    switch (result) {
      case Ok(:final value):
        final updated = job.copyWith(
          attachments: [...job.attachments, value],
        );
        state = AsyncData(updated);
        return null;
      case Err(:final failure):
        return failure.message;
    }
  }
}
