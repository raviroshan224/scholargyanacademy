import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/services/remote_services/api_endpoints.dart';
import '../../../config/services/remote_services/errors/failure.dart';
import '../../../config/services/remote_services/http_service.dart';
import '../../../config/services/remote_services/http_service_provider.dart';
import '../models/mock_test_models.dart';

typedef MockTestResult = Either<Failure, MockTestListResponse>;

Map<String, String>? _buildQuery({int? page, int? limit}) {
  final params = <String, String>{};
  if (page != null && page > 0) params['page'] = '$page';
  if (limit != null && limit > 0) params['limit'] = '$limit';
  return params.isEmpty ? null : params;
}

abstract class MockTestService {
  Future<MockTestResult> fetchMockTests({
    required String courseId,
    int? page,
    int? limit,
  });

  Future<Either<Failure, MockTest>> fetchMockTestDetail({
    required String courseId,
    required String mockTestId,
  });
}

class MockTestServiceImpl implements MockTestService {
  MockTestServiceImpl(this._http);

  final HttpService _http;

  @override
  Future<MockTestResult> fetchMockTests({
    required String courseId,
    int? page,
    int? limit,
  }) async {
    final query = _buildQuery(page: page, limit: limit);
    final endpoint =
        '${ApiEndPoints.mockTestsByCourse}/$courseId/with-attempts';
    final response = await _http.get(
      endpoint,
      requiresAuth: true,
      queryParameters: query,
    );
    return response.fold(
      Left.new,
      (success) {
        final parsed = _parseMockTests(success.data, courseId);
        if (parsed == null) {
          return Left(Failure(message: 'Unable to parse mock tests'));
        }
        return Right(parsed);
      },
    );
  }

  @override
  Future<Either<Failure, MockTest>> fetchMockTestDetail({
    required String courseId,
    required String mockTestId,
  }) async {
    final listResult = await fetchMockTests(
      courseId: courseId,
      limit: 200,
    );

    return listResult.fold(
      Left.new,
      (payload) {
        final match = _findMockTest(payload.tests, mockTestId);
        if (match != null) {
          return Right(match);
        }
        return Right(
          MockTest(
            id: mockTestId,
            courseId: courseId,
          ),
        );
      },
    );
  }

  MockTest? _findMockTest(List<MockTest> tests, String mockTestId) {
    for (final test in tests) {
      if (test.id == mockTestId) {
        return test;
      }
      final extra = test.extra;
      if (extra != null) {
        final slug = extra['slug']?.toString();
        final legacyId = extra['mockTestId']?.toString();
        if (slug == mockTestId || legacyId == mockTestId) {
          return test;
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractData(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      return {'data': data};
    }
    return null;
  }

  MockTestListResponse? _parseMockTests(dynamic raw, String courseId) {
    if (raw is List) {
      final tests = raw
          .whereType<Map>()
          .map((item) => item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item as Map))
          .map(MockTest.fromJson)
          .toList();
      final resolved = tests
          .map((test) => test.courseId.isNotEmpty
              ? test
              : test.copyWith(courseId: courseId))
          .toList();
      return MockTestListResponse(tests: resolved, meta: null);
    }

    final payload = _extractData(raw);
    if (payload == null) {
      return null;
    }

    final parsed = MockTestListResponse.fromJson(payload);
    final resolvedTests = parsed.tests
        .map((test) =>
            test.courseId.isNotEmpty ? test : test.copyWith(courseId: courseId))
        .toList();
    return MockTestListResponse(tests: resolvedTests, meta: parsed.meta);
  }
}

final mockTestServiceProvider = Provider<MockTestService>((ref) {
  final http = ref.read(httpServiceProvider);
  return MockTestServiceImpl(http);
});
