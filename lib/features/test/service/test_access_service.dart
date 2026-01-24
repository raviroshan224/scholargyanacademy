import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/services/remote_services/api_endpoints.dart';
import '../../../config/services/remote_services/errors/failure.dart';
import '../../../config/services/remote_services/http_service.dart';
import '../../../config/services/remote_services/http_service_provider.dart';

abstract class TestAccessService {
  Future<Either<Failure, Map<String, dynamic>>> purchaseTest({
    required String testId,
    String? promoCode,
  });
}

class TestAccessServiceImpl implements TestAccessService {
  TestAccessServiceImpl(this._http);
  final HttpService _http;

  @override
  Future<Either<Failure, Map<String, dynamic>>> purchaseTest({
    required String testId,
    String? promoCode,
  }) async {
    final body = {
      'paymentType': 'test_purchase',
      'referenceId': testId,
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
    };
    final response = await _http.post(
      ApiEndPoints.paymentsInitiate,
      requiresAuth: true,
      data: body,
    );
    return response.fold(
      Left.new,
      (success) {
        final map = success.data is Map<String, dynamic>
            ? success.data as Map<String, dynamic>
            : success.data is Map
                ? Map<String, dynamic>.from(success.data as Map)
                : null;
        if (map == null) {
          return Left(Failure(message: 'Unexpected payment response'));
        }
        return Right(map);
      },
    );
  }
}

final testAccessServiceProvider = Provider<TestAccessService>((ref) {
  final http = ref.read(httpServiceProvider);
  return TestAccessServiceImpl(http);
});
