import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/job_model.dart';

class JobLocalDatasource {
  Box<JobModel> get _box => Hive.box<JobModel>(AppConstants.jobsBoxName);

  Future<void> saveJobs(List<JobModel> jobs) async {
    final map = {for (final j in jobs) j.id: j};
    await _box.putAll(map);
  }

  Future<void> saveJob(JobModel job) => _box.put(job.id, job);

  List<JobModel> getAllJobs() => _box.values.toList();

  JobModel? getJob(String id) {
    final job = _box.get(id);
    if (job == null) throw CacheException('Job $id not found in cache.');
    return job;
  }

  Future<void> deleteJob(String id) => _box.delete(id);
}
