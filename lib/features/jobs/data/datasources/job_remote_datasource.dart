import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/repositories/job_repository.dart';
import '../models/job_model.dart';

class JobRemoteDatasource {
  final Dio _dio;

  JobRemoteDatasource(this._dio);

  Future<List<JobModel>> getJobs({
    required int page,
    required int limit,
    required JobsFilter filter,
    CancelToken? cancelToken,
  }) async {
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
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to load jobs.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<JobModel> getJob(String id) async {
    try {
      final response = await _dio.get('/jobs/$id');
      return JobModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to load job.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<JobModel> updateJobStatus(String id, JobStatus newStatus) async {
    try {
      final response = await _dio.patch(
        '/jobs/$id',
        data: {'status': newStatus.apiValue},
      );
      return JobModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Status update failed.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AttachmentModel> uploadAttachment(
    String jobId,
    File file, {
    void Function(int, int)? onProgress,
  }) async {
    final filename = file.path.split(Platform.pathSeparator).last;
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: filename),
      });

      final response = await _dio.post(
        '/jobs/$jobId/attachments',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: const Duration(seconds: AppConstants.receiveTimeoutMs ~/ 1000 * 4),
        ),
        onSendProgress: onProgress,
      );

      return AttachmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Upload failed.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
