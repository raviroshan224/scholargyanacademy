import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../config/services/remote_services/http_service_provider.dart';
import '../../../../config/services/secure_storage_provider.dart';
import '../../service/auth_api.dart';
import '../../service/auth_service.dart';
import '../../service/user_service.dart';
import '../auth_state.dart';
import '../auth_view_model.dart';

final authApiProvider = Provider<AuthApi>((Ref ref) {
  final httpService = ref.watch(httpServiceProvider);
  return AuthApi(httpService);
});

final authServiceProvider = Provider<AuthService>((Ref ref) {
  final api = ref.watch(authApiProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final httpService = ref.watch(httpServiceProvider);
  return AuthServiceImpl(api, secureStorage, httpService);
});

final userServiceProvider = Provider<UserService>((Ref ref) {
  final httpService = ref.watch(httpServiceProvider);
  return UserServiceImpl(httpService);
});

final authNotifierProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  Ref ref,
) {
  final authService = ref.watch(authServiceProvider);
  final userService = ref.watch(userServiceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthViewModel(authService, userService, secureStorage);
});
