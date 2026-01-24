import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/api_endpoints.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/http_service.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/http_service_provider.dart';

/// Simple payment service - only initiates payment and returns redirect URL
class SimplePaymentService {
  final HttpService _http;

  SimplePaymentService(this._http);

  /// Initiates payment and returns eSewa redirect URL
  ///
  /// Returns the redirect URL on success, null on failure
  Future<String?> initiatePayment({
    required String paymentType,
    required String referenceId,
    String? promoCode,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'paymentType': paymentType,
        'referenceId': referenceId,
      };

      // Only include promoCode if provided and non-empty
      if (promoCode != null && promoCode.isNotEmpty) {
        payload['promoCode'] = promoCode;
      }

      final response = await _http.post(
        ApiEndPoints.paymentsInitiate,
        data: payload,
        requiresAuth: true,
      );

      return response.fold(
        (failure) {
          // Return null on failure
          return null;
        },
        (result) {
          try {
            final data = result.data;
            if (data is! Map) {
              return null;
            }

            // Extract esewaRedirectUrl from response
            final redirectUrl = data['esewaRedirectUrl']?.toString();

            if (redirectUrl == null || redirectUrl.isEmpty) {
              return null;
            }

            return redirectUrl;
          } catch (e) {
            return null;
          }
        },
      );
    } catch (e) {
      return null;
    }
  }
}

final simplePaymentServiceProvider = Provider<SimplePaymentService>((ref) {
  final http = ref.watch(httpServiceProvider);
  return SimplePaymentService(http);
});
