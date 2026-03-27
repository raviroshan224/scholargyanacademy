import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/features/courses/model/enrollment_models.dart';

import '../../../config/services/remote_services/api_endpoints.dart';
import '../../../config/services/remote_services/errors/failure.dart';
import '../../../config/services/remote_services/http_service.dart';
import '../../../config/services/remote_services/http_service_provider.dart';
import '../model/live_class_models.dart';

abstract class ListmentService {
  Future<Either<Failure, List<ListmentModel>>> myCourses();
  Future<Either<Failure, ListmentModel>> byId(String id);
  Future<Either<Failure, Map<String, dynamic>>> courseDetails(String courseId);
  Future<Either<Failure, PagedLiveClasses>> myLiveClasses({
    String? courseId,
    String? subjectId,
    String status,
    int page,
    int limit,
  });
}

class ListmentServiceImpl implements ListmentService {
  final HttpService _http;
  ListmentServiceImpl(this._http);

  @override
  Future<Either<Failure, List<ListmentModel>>> myCourses() async {
    final res = await _http.get(
      ApiEndPoints.ListmentsMyCourses,
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      final list =
          (r.data as List?)
              ?.map((e) => ListmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <ListmentModel>[];
      return Right(list);
    });
  }

  @override
  Future<Either<Failure, ListmentModel>> byId(String id) async {
    final res = await _http.get(
      '${ApiEndPoints.ListmentsById}/$id',
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      final data = r.data;
      if (data is Map<String, dynamic>)
        return Right(ListmentModel.fromJson(data));
      if (data is Map)
        return Right(ListmentModel.fromJson(data.cast<String, dynamic>()));
      return Left(Failure(message: 'Invalid Listment response format'));
    });
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> courseDetails(
    String courseId,
  ) async {
    final res = await _http.get(
      '${ApiEndPoints.ListmentsCourseDetails}/$courseId/details',
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

final ListmentServiceProvider = Provider<ListmentService>((ref) {
  final http = ref.read(httpServiceProvider);
  return ListmentServiceImpl(http);
});
