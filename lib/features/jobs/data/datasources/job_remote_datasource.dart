import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/repositories/job_repository.dart';
import '../models/job_model.dart';

class JobRemoteDatasource {
  final Dio? _dio;

  JobRemoteDatasource([this._dio]);

  Future<List<JobModel>> getJobs({
    required int page,
    required int limit,
    required JobsFilter filter,
    CancelToken? cancelToken,
  }) async {
    if (_dio != null) {
      try {
        final response = await _dio.get(
          '/jobs',
          queryParameters: {
            'page': page,
            'limit': limit,
            if (filter.search?.isNotEmpty == true) 'search': filter.search,
            if (filter.statuses.isNotEmpty)
              'status': filter.statuses.map((s) => s.apiValue).join(','),
            if (filter.priorities.isNotEmpty)
              'priority': filter.priorities.map((p) => p.apiValue).join(','),
            if (filter.from != null) 'from': filter.from!.toIso8601String(),
            if (filter.to != null) 'to': filter.to!.toIso8601String(),
            if (filter.overdueOnly) 'overdue': 'true',
          },
          cancelToken: cancelToken,
        );

        final items = response.data['data'] as List<dynamic>? ?? [];
        return items
            .map((e) => JobModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) rethrow;
        // Generate mock jobs if remote mock endpoint is unreachable
        return _getMockJobs(page, limit, filter);
      } catch (_) {
        return _getMockJobs(page, limit, filter);
      }
    }
    return _getMockJobs(page, limit, filter);
  }

  Future<JobModel> getJob(String id) async {
    if (_dio != null) {
      try {
        final response = await _dio.get('/jobs/$id');
        return JobModel.fromJson(response.data as Map<String, dynamic>);
      } catch (_) {
        return _createMockJob(id);
      }
    }
    return _createMockJob(id);
  }

  Future<JobModel> updateJobStatus(String id, JobStatus newStatus) async {
    if (_dio != null) {
      try {
        final response = await _dio.patch(
          '/jobs/$id',
          data: {'status': newStatus.apiValue},
        );
        return JobModel.fromJson(response.data as Map<String, dynamic>);
      } catch (_) {
        return _createMockJob(id, status: HiveJobStatus.fromDomain(newStatus));
      }
    }
    return _createMockJob(id, status: HiveJobStatus.fromDomain(newStatus));
  }

  Future<AttachmentModel> uploadAttachment(
    String jobId,
    File file, {
    void Function(int, int)? onProgress,
  }) async {
    final filename = file.path.split(Platform.pathSeparator).last;
    if (_dio != null) {
      try {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: filename),
        });

        final response = await _dio.post(
          '/jobs/$jobId/attachments',
          data: formData,
          options: Options(
            headers: {'Content-Type': 'multipart/form-data'},
            sendTimeout: const Duration(
              seconds: AppConstants.receiveTimeoutMs ~/ 1000 * 4,
            ),
          ),
          onSendProgress: onProgress,
        );

        return AttachmentModel.fromJson(response.data as Map<String, dynamic>);
      } catch (_) {
        // Fallback simulation
        onProgress?.call(100, 100);
        return AttachmentModel(
          id: 'att_${DateTime.now().millisecondsSinceEpoch}',
          filename: filename,
          url: file.path,
          mimeType: 'image/jpeg',
          sizeBytes: await file.length(),
        );
      }
    }

    onProgress?.call(100, 100);
    return AttachmentModel(
      id: 'att_${DateTime.now().millisecondsSinceEpoch}',
      filename: filename,
      url: file.path,
      mimeType: 'image/jpeg',
      sizeBytes: await file.length(),
    );
  }

  List<JobModel> _getMockJobs(int page, int limit, JobsFilter filter) {
    final now = DateTime.now();

    // ── 50-job mock dataset ──────────────────────────────────────────────────
    // Enough to exercise 3+ pages at the default page size of 15.
    final allMockJobs = List.generate(50, (i) {
      final idx = i + 1;
      final statuses = [
        HiveJobStatus.pending,
        HiveJobStatus.inProgress,
        HiveJobStatus.completed,
        HiveJobStatus.cancelled,
      ];
      final priorities = [
        HiveJobPriority.low,
        HiveJobPriority.normal,
        HiveJobPriority.high,
        HiveJobPriority.urgent,
      ];
      final titles = [
        'HVAC Compressor Inspection',
        'Electrical Panel Replacement',
        'Plumbing Leak Repair',
        'Fire Alarm Calibration',
        'Generator Load Test',
        'Water Filter Servicing',
        'Elevator Safety Inspection',
        'Boiler Maintenance',
        'Security System Upgrade',
        'Solar Panel Cleaning',
      ];
      final status = statuses[i % statuses.length];
      final priority = priorities[(i ~/ 4) % priorities.length];
      final title = '${titles[i % titles.length]} #$idx';
      // Alternate past/future scheduled times to get realistic overdue spread
      final scheduledAt = i.isEven
          ? now.subtract(Duration(hours: i + 1))
          : now.add(Duration(hours: i + 1));

      final locations = const [
        [37.7749, -122.4194], // SF Center
        [37.7816, -122.4056], // SF SOMA
        [37.7952, -122.4028], // SF FiDi
        [37.7694, -122.4862], // SF Golden Gate Park
        [37.7516, -122.4177], // SF Mission
        [37.7338, -122.4463], // SF Sunnyside
      ];
      final loc = locations[i % locations.length];
      final hasLocation = i % 10 != 0;

      return JobModel(
        id: 'job_${idx.toString().padLeft(3, '0')}',
        title: title,
        description: 'Standard maintenance task for job $idx. Inspect, service, and document.',
        status: status,
        priority: priority,
        assignedTo: i.isEven ? 'John Doe' : 'Jane Smith',
        scheduledAt: scheduledAt,
        updatedAt: now,
        latitude: hasLocation ? loc[0] : null,
        longitude: hasLocation ? loc[1] : null,
      );
    });

    // ── Apply filters (AND logic) ────────────────────────────────────────────
    var filtered = allMockJobs;

    if (filter.search != null && filter.search!.isNotEmpty) {
      final q = filter.search!.toLowerCase();
      filtered = filtered
          .where(
            (j) =>
                j.title.toLowerCase().contains(q) ||
                j.description.toLowerCase().contains(q),
          )
          .toList();
    }
    if (filter.statuses.isNotEmpty) {
      filtered = filtered
          .where((j) => filter.statuses.contains(j.status.toDomain()))
          .toList();
    }
    if (filter.priorities.isNotEmpty) {
      filtered = filtered
          .where((j) => filter.priorities.contains(j.priority.toDomain()))
          .toList();
    }
    if (filter.overdueOnly) {
      filtered = filtered.where((j) => j.toDomain().isOverdue).toList();
    }
    if (filter.from != null) {
      filtered = filtered.where((j) => !j.scheduledAt.isBefore(filter.from!)).toList();
    }
    if (filter.to != null) {
      filtered = filtered.where((j) => !j.scheduledAt.isAfter(filter.to!)).toList();
    }

    // ── Paginate with skip/take ──────────────────────────────────────────────
    final offset = (page - 1) * limit;
    if (offset >= filtered.length) return [];
    return filtered.skip(offset).take(limit).toList();
  }

  JobModel _createMockJob(String id, {HiveJobStatus? status}) {
    final now = DateTime.now();
    return JobModel(
      id: id,
      title: 'Field Service Job $id',
      description: 'Standard maintenance task and inspection.',
      status: status ?? HiveJobStatus.inProgress,
      priority: HiveJobPriority.normal,
      assignedTo: 'Technician',
      scheduledAt: now,
      updatedAt: now,
      latitude: 37.7749,
      longitude: -122.4194,
    );
  }
}
