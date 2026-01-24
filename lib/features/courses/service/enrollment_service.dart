import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/api_endpoints.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/errors/failure.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/http_service.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/http_service_provider.dart';

import '../model/enrollment_models.dart';
import '../model/live_class_models.dart';

abstract class EnrollmentService {
  Future<Either<Failure, List<EnrollmentModel>>> myCourses();
  Future<Either<Failure, EnrollmentModel>> byId(String id);
  Future<Either<Failure, Map<String, dynamic>>> courseDetails(String courseId);
  Future<Either<Failure, PagedLiveClasses>> myLiveClasses({
    String? courseId,
    String? subjectId,
    String status,
    int page,
    int limit,
  });
}

class EnrollmentServiceImpl implements EnrollmentService {
  final HttpService _http;
  EnrollmentServiceImpl(this._http);

  @override
  Future<Either<Failure, List<EnrollmentModel>>> myCourses() async {
    final res = await _http.get(
      ApiEndPoints.enrollmentsMyCourses,
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      final list =
          (r.data as List?)
              ?.map((e) => EnrollmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <EnrollmentModel>[];
      return Right(list);
    });
  }

  @override
  Future<Either<Failure, EnrollmentModel>> byId(String id) async {
    final res = await _http.get(
      '${ApiEndPoints.enrollmentsById}/$id',
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      final data = r.data;
      if (data is Map<String, dynamic>)
        return Right(EnrollmentModel.fromJson(data));
      if (data is Map)
        return Right(EnrollmentModel.fromJson(data.cast<String, dynamic>()));
      return Left(Failure(message: 'Invalid enrollment response format'));
    });
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> courseDetails(
    String courseId,
  ) async {
    final res = await _http.get(
      '${ApiEndPoints.enrollmentsCourseDetails}/$courseId/details',
      requiresAuth: true,
    );
    return res.fold(
      (l) => Left(l),
      (r) => Right((r.data as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<Either<Failure, PagedLiveClasses>> myLiveClasses({
    String? courseId,
    String? subjectId,
    String status = 'ongoing',
    int page = 1,
    int limit = 10,
  }) async {
    final query = <String, dynamic>{
      'status': status,
      'page': page,
      'limit': limit,
    };
    if (courseId != null && courseId.isNotEmpty) {
      query['courseId'] = courseId;
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      query['subjectId'] = subjectId;
    }

    final res = await _http.get(
      ApiEndPoints.liveClassesMyClasses,
      requiresAuth: true,
      queryParameters: query,
    );

    return res.fold(
      (failure) => Left(failure),
      (response) => Right(PagedLiveClasses.fromJson(response.data)),
    );
  }
}

final enrollmentServiceProvider = Provider<EnrollmentService>((ref) {
  final http = ref.read(httpServiceProvider);
  return EnrollmentServiceImpl(http);
});
