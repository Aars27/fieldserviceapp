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
    if (page > 2) return [];

    final now = DateTime.now();
    final allMockJobs = [
      JobModel(
        id: 'job_001',
        title: 'HVAC Compressor Inspection',
        description:
            'Check high-pressure valve and replace compressor filter on rooftop unit 3.',
        status: HiveJobStatus.inProgress,
        priority: HiveJobPriority.urgent,
        assignedTo: 'John Doe',
        scheduledAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now,
        latitude: 37.7749,
        longitude: -122.4194,
        timeline: [
          StatusEventModel(
            id: 'evt_1',
            status: HiveJobStatus.pending,
            note: 'Job assigned',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          StatusEventModel(
            id: 'evt_2',
            status: HiveJobStatus.inProgress,
            note: 'Started diagnostics on site',
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      JobModel(
        id: 'job_002',
        title: 'Main Circuit Breaker Replacement',
        description: 'Replace 200A main service breaker in electrical room B.',
        status: HiveJobStatus.pending,
        priority: HiveJobPriority.high,
        assignedTo: 'John Doe',
        scheduledAt: now.add(const Duration(hours: 4)),
        updatedAt: now,
        latitude: 37.7833,
        longitude: -122.4167,
      ),
      JobModel(
        id: 'job_003',
        title: 'Water Filtration Unit Servicing',
        description: 'Quarterly sediment filter replacement and chlorine test.',
        status: HiveJobStatus.completed,
        priority: HiveJobPriority.normal,
        assignedTo: 'John Doe',
        scheduledAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      JobModel(
        id: 'job_004',
        title: 'Emergency Generator Load Test',
        description:
            'Perform 30-minute full load bank test and log fuel consumption.',
        status: HiveJobStatus.pending,
        priority: HiveJobPriority.urgent,
        assignedTo: 'John Doe',
        scheduledAt: now.add(const Duration(days: 1)),
        updatedAt: now,
      ),
      JobModel(
        id: 'job_005',
        title: 'Fire Alarm Sensor Calibration',
        description: 'Calibrate optical smoke detectors on floors 2 through 5.',
        status: HiveJobStatus.inProgress,
        priority: HiveJobPriority.normal,
        assignedTo: 'John Doe',
        scheduledAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now,
      ),
    ];

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

    return filtered;
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
    );
  }
}
