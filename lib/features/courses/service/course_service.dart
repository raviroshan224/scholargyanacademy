import 'dart:convert';

import 'package:either_dart/either.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/services/remote_services/api_endpoints.dart';
import '../../../config/services/remote_services/errors/failure.dart';
import '../../../config/services/remote_services/http_service.dart';
import '../../../config/services/remote_services/http_service_provider.dart';
import '../model/course_models.dart';

abstract class CourseService {
  Future<Either<Failure, PagedCourses>> list({
    int page,
    int limit,
    String? search,
    String? categoryId,
  });
  Future<Either<Failure, CourseModel>> byId(String id);
  Future<Either<Failure, CourseModel>> bySlug(String slug);
  Future<Either<Failure, Map<String, dynamic>>> details(String id);
  Future<Either<Failure, List<SubjectModel>>> subjectsByCourse(String courseId);
  Future<Either<Failure, List<LecturerModel>>> lecturersByCourse(
    String courseId,
  );
  Future<Either<Failure, List<CourseMaterialModel>>> materialsByCourse(
    String courseId,
  );
  Future<Either<Failure, List<CourseMaterialModel>>> materialsBySubject(
    String subjectId,
  );
  Future<Either<Failure, List<CourseMaterialModel>>> materialsByChapter(
    String chapterId,
  );
  Future<Either<Failure, List<LectureModel>>> lecturesBySubject(
    String subjectId,
  );
  Future<Either<Failure, CourseMaterialModel>> materialById(String id);
  Future<Either<Failure, Map<String, dynamic>>> downloadMaterial(String id);
  Future<Either<Failure, List<LectureModel>>> freeLectures();
  Future<Either<Failure, LectureModel>> lectureById(String id);
  Future<Either<Failure, Map<String, dynamic>>> previewLecture(String id);
  Future<Either<Failure, Map<String, dynamic>>> watchLecture(String id);
  Future<Either<Failure, void>> completeLecture(String lectureId);
  Future<Either<Failure, void>> enrollFreeCourse(String courseId);
  Future<Either<Failure, List<MockTestModel>>> mockTestsByCourse(
    String courseId, {
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, Map<String, dynamic>>> save(String id);
  Future<Either<Failure, Map<String, dynamic>>> removeSaved(String id);
  Future<Either<Failure, bool>> isSaved(String id);
  Future<Either<Failure, PagedCourses>> savedMine({
    int page,
    int limit,
    String? search,
  });
}

class CourseServiceImpl implements CourseService {
  final HttpService _http;
  CourseServiceImpl(this._http);

  @override
  Future<Either<Failure, PagedCourses>> list({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
  }) async {
    final qp = {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    };
    final res = await _http.get(
      ApiEndPoints.courses,
      queryParameters: qp,
      requiresAuth: false,
    );
    return res.fold((l) => Left(l), (r) {
      // Print the raw JSON response for debugging
      print('Raw courses API response: ${jsonEncode(r.data)}');
      return Right(PagedCourses.fromJson(r.data));
    });
  }

  @override
  Future<Either<Failure, CourseModel>> byId(String id) async {
    final res = await _http.get(
      '${ApiEndPoints.courseById}/$id',
      requiresAuth: false,
    );
    return res.fold((l) => Left(l), (r) => Right(CourseModel.fromJson(r.data)));
  }

  @override
  Future<Either<Failure, CourseModel>> bySlug(String slug) async {
    final res = await _http.get(
      '${ApiEndPoints.courseBySlug}/$slug',
      requiresAuth: false,
    );
    return res.fold((l) => Left(l), (r) => Right(CourseModel.fromJson(r.data)));
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> details(String id) async {
    final res = await _http.get(
      '${ApiEndPoints.courseDetails}/$id/details',
      requiresAuth: true,
    );
    return res.fold(
      (l) => Left(l),
      (r) => Right((r.data as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<Either<Failure, List<SubjectModel>>> subjectsByCourse(
    String courseId,
  ) async {
    final res = await _http.get(
      '${ApiEndPoints.subjectsByCourse}/$courseId',
      requiresAuth: false,
    );
    return res.fold((l) => Left(l), (r) {
      final list =
          (r.data as List?)
              ?.map((e) => SubjectModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <SubjectModel>[];
      return Right(list);
    });
  }

  @override
  Future<Either<Failure, List<LecturerModel>>> lecturersByCourse(
    String courseId,
  ) async {
    final res = await _http.get(
      '${ApiEndPoints.lecturersByCourse}/$courseId',
      requiresAuth: false,
    );
    return res.fold((l) => Left(l), (r) {
      try {
        final pretty = JsonEncoder.withIndent('  ').convert(r.data);
        debugPrint('lecturersByCourse($courseId) response:\n$pretty');
      } catch (_) {
        debugPrint('lecturersByCourse($courseId) response: ${r.data}');
      }
      final list =
          (r.data as List?)
              ?.map((e) => LecturerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <LecturerModel>[];
      return Right(list);
    });
  }

  @override
  Future<Either<Failure, List<CourseMaterialModel>>> materialsByCourse(
    String courseId,
  ) async {
    final res = await _http.get(
      '${ApiEndPoints.courseMaterialsByCourse}/$courseId',
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      try {
        final pretty = JsonEncoder.withIndent('  ').convert(r.data);
        debugPrint('materialsByCourse($courseId) response:\n$pretty');
      } catch (_) {
        debugPrint('materialsByCourse($courseId) response: ${r.data}');
      }
      final list =
          (r.data as List?)
              ?.map(
                (e) => CourseMaterialModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <CourseMaterialModel>[];
      return Right(list);
    });
  }

  @override
  Future<Either<Failure, List<CourseMaterialModel>>> materialsBySubject(
    String subjectId,
  ) async {
    final res = await _http.get(
      '${ApiEndPoints.courseMaterialsBySubject}/$subjectId',
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      final list =
          (r.data as List?)
              ?.map(
                (e) => CourseMaterialModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <CourseMaterialModel>[];
      return Right(list);
    });
  }

  @override
  Future<Either<Failure, List<CourseMaterialModel>>> materialsByChapter(
    String chapterId,
  ) async {
    final res = await _http.get(
      '${ApiEndPoints.courseMaterialsByChapter}/$chapterId',
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      final list =
          (r.data as List?)
              ?.map(
                (e) => CourseMaterialModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <CourseMaterialModel>[];
      return Right(list);
    });
  }

  @override
  Future<Either<Failure, CourseMaterialModel>> materialById(String id) async {
    final res = await _http.get(
      '${ApiEndPoints.courseMaterialById}/$id',
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      final data = r.data;
      if (data is Map<String, dynamic>) {
        return Right(CourseMaterialModel.fromJson(data));
      }
      if (data is Map) {
        return Right(
          CourseMaterialModel.fromJson(data.cast<String, dynamic>()),
        );
      }
      return Left(Failure(message: 'Invalid material response format'));
    });
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> downloadMaterial(
    String id,
  ) async {
    final res = await _http.post(
      '${ApiEndPoints.courseMaterialDownload}/$id/download',
      requiresAuth: true,
    );
    return res.fold(
      (l) => Left(l),
      (r) => Right((r.data as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<Either<Failure, List<LectureModel>>> freeLectures() async {
    final res = await _http.get(ApiEndPoints.lecturesFree, requiresAuth: false);
    return res.fold((l) => Left(l), (r) {
      final list =
          (r.data as List?)
              ?.map((e) => LectureModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <LectureModel>[];
      return Right(list);
    });
  }

  @override
  Future<Either<Failure, List<LectureModel>>> lecturesBySubject(
    String subjectId,
  ) async {
    final res = await _http.get(
      '${ApiEndPoints.lecturesBySubject}/$subjectId',
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      try {
        final pretty = JsonEncoder.withIndent('  ').convert(r.data);
        debugPrint('lecturesBySubject($subjectId) response:\n$pretty');
      } catch (_) {
        debugPrint('lecturesBySubject($subjectId) response: ${r.data}');
      }
      final list =
          (r.data as List?)
              ?.map((e) => LectureModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <LectureModel>[];
      return Right(list);
    });
  }

  @override
  Future<Either<Failure, LectureModel>> lectureById(String id) async {
    final res = await _http.get(
      '${ApiEndPoints.lectures}/$id',
      requiresAuth: false,
    );
    return res.fold((l) => Left(l), (r) {
      final data = r.data;
      if (data is Map<String, dynamic>) {
        return Right(LectureModel.fromJson(data));
      }
      if (data is Map) {
        return Right(LectureModel.fromJson(data.cast<String, dynamic>()));
      }
      return Left(Failure(message: 'Invalid lecture response format'));
    });
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> previewLecture(
    String id,
  ) async {
    final res = await _http.post(
      '${ApiEndPoints.lectureAdminPreview}/$id/preview',
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      final data = r.data;
      if (data is Map<String, dynamic>) return Right(data);
      if (data is Map) return Right(data.cast<String, dynamic>());
      return Left(Failure(message: 'Invalid lecture preview response format'));
    });
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> watchLecture(String id) async {
    final res = await _http.post(
      '${ApiEndPoints.lectures}/$id/watch',
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) {
      final data = r.data;
      if (data is Map<String, dynamic>) return Right(data);
      if (data is Map) return Right(data.cast<String, dynamic>());
      return Left(Failure(message: 'Invalid lecture watch response format'));
    });
  }

  @override
  Future<Either<Failure, void>> completeLecture(String lectureId) async {
    final res = await _http.post(
      ApiEndPoints.completeLecture,
      data: {'lectureId': lectureId},
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> enrollFreeCourse(String courseId) async {
    final res = await _http.post(
      ApiEndPoints.enrollFreeCourse,
      data: {'courseId': courseId},
      requiresAuth: true,
    );
    return res.fold((l) => Left(l), (r) => const Right(null));
  }

  @override
  Future<Either<Failure, List<MockTestModel>>> mockTestsByCourse(
    String courseId, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _http.get(
      '${ApiEndPoints.mockTestsByCourse}/$courseId/with-attempts',
      requiresAuth: true,
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );
    return res.fold((l) => Left(l), (r) {
      try {
        final pretty = JsonEncoder.withIndent('  ').convert(r.data);
        debugPrint('mockTestsByCourse($courseId) response:\n$pretty');
      } catch (_) {
        debugPrint('mockTestsByCourse($courseId) response: ${r.data}');
      }
      final data = r.data;
      if (data is List) {
        final list = <MockTestModel>[];
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            list.add(MockTestModel.fromJson(item));
          } else if (item is Map) {
            list.add(MockTestModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        return Right(list);
      }
      return const Right(<MockTestModel>[]);
    });
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> save(String id) async {
    final res = await _http.post(
      '${ApiEndPoints.courseSave}/$id/save',
      requiresAuth: true,
    );
    return res.fold(
      (l) => Left(l),
      (r) => Right((r.data as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> removeSaved(String id) async {
    final res = await _http.delete(
      '${ApiEndPoints.courseSave}/$id/save',
      requiresAuth: true,
    );
    return res.fold(
      (l) => Left(l),
      (r) => Right((r.data as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<Either<Failure, bool>> isSaved(String id) async {
    final res = await _http.get(
      '${ApiEndPoints.courseIsSaved}/$id/is-saved',
      requiresAuth: true,
    );
    return res.fold(
      (l) => Left(l),
      (r) => Right((r.data as Map)['isSaved'] == true),
    );
  }

  @override
  Future<Either<Failure, PagedCourses>> savedMine({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final qp = {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _http.get(
      ApiEndPoints.courseSavedMine,
      queryParameters: qp,
      requiresAuth: true,
    );
    return res.fold(
      (l) => Left(l),
      (r) => Right(PagedCourses.fromJson(r.data)),
    );
  }
}

final courseServiceProvider = Provider<CourseService>((ref) {
  final http = ref.read(httpServiceProvider);
  return CourseServiceImpl(http);
});
