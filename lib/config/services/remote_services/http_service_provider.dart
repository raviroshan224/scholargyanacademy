import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'http_service.dart';
import 'http_service_impl.dart';

/// This is a provider for your HttpService.
/// It is where the actual implementation of the HttpService is created.
/// Whenever someone tries to read this provider, they'll get the instance of
/// HttpService returned by `HttpServiceImpl().

final httpServiceProvider = Provider<HttpService>((Ref ref) {
  return HttpServiceImpl(
      ref); // Create and return a new instance of HttpService.
});
