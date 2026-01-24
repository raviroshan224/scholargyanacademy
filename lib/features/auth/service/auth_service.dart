import 'package:either_dart/either.dart';
import 'package:scholarsgyanacademy/config/local_db/hive/hive_data_source.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/api_endpoints.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/errors/failure.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/http_service.dart';
import 'package:scholarsgyanacademy/config/services/secure_storage_service.dart';
import 'package:scholarsgyanacademy/features/auth/model/auth_models.dart';
import 'package:scholarsgyanacademy/features/auth/model/email_verification_request.dart';
import 'package:scholarsgyanacademy/features/auth/model/login_request.dart';
import 'package:scholarsgyanacademy/features/auth/model/register_request.dart';
import 'package:scholarsgyanacademy/features/auth/service/auth_api.dart';
import 'package:scholarsgyanacademy/network_layer/network_layer.dart';

abstract class AuthService {
  Future<Either<Failure, AuthResponseModel>> login(LoginRequest request);
  Future<Either<Failure, void>> register(RegisterRequest request);
  Future<Either<Failure, void>> sendEmailVerification(
    SendEmailVerificationRequest request,
  );
  Future<Either<Failure, void>> verifyEmailOtp(VerifyEmailOtpRequest request);
  Future<Either<Failure, void>> forgotPassword(String email);
  Future<Either<Failure, void>> verifyOtp(String email, String otp);
  Future<Either<Failure, void>> resetPassword(
    String email,
    String otp,
    String password,
  );
  Future<Either<Failure, AuthTokensModel>> refreshToken();
  Future<Either<Failure, void>> logout();
}

class AuthServiceImpl implements AuthService {
  final AuthApi _api;
  final SecureStorageService _secureStorage;
  final HttpService _httpService;

  AuthServiceImpl(this._api, this._secureStorage, this._httpService);

  @override
  Future<Either<Failure, AuthResponseModel>> login(LoginRequest request) async {
    final response = await _api.login(request);
    return response.fold((failure) => Left(failure), (authResponse) async {
      await _secureStorage.write('token', authResponse.token);
      await _secureStorage.write('refreshToken', authResponse.refreshToken);
      await _secureStorage.write(
        'tokenExpires',
        authResponse.tokenExpires.toString(),
      );
      await _secureStorage.write(
        'loginTimestamp',
        DateTime.now().toIso8601String(),
      );

      // Keep legacy data stores in sync so startup flows relying on Hive/ApiConfig remain functional.
      try {
        await HiveDataSource().updateAccessToken(authResponse.token);
        await HiveDataSource().updateRefreshToken(authResponse.refreshToken);
        await HiveDataSource().setTokenExpiration(
          authResponse.tokenExpires.toString(),
        );
      } catch (_) {}
      try {
        await ApiConfig().setAccessToken(value: authResponse.token);
        await ApiConfig().setRefreshToken(
          refreshToken: authResponse.refreshToken,
        );
      } catch (_) {}
      return Right(authResponse);
    });
  }

  @override
  Future<Either<Failure, void>> register(RegisterRequest request) async {
    final response = await _api.register(request);
    return response.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification(
    SendEmailVerificationRequest request,
  ) async {
    final response = await _api.sendEmailVerificationOtp(request);
    return response.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> verifyEmailOtp(
    VerifyEmailOtpRequest request,
  ) async {
    final response = await _api.verifyEmailOtp(request);
    return response.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    final response = await _api.forgotPassword(email);
    return response.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> verifyOtp(String email, String otp) async {
    final response = await _api.verifyOtp({'email': email, 'otp': otp});
    return response.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> resetPassword(
    String email,
    String otp,
    String password,
  ) async {
    final response = await _api.resetPassword({
      'email': email,
      'otp': otp,
      'password': password,
    });
    return response.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, AuthTokensModel>> refreshToken() async {
    final refreshToken = await _secureStorage.read('refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      return Left(Failure(message: 'No refresh token available'));
    }
    final response = await _httpService.post(
      ApiEndPoints.refreshTokenUrl,
      data: {'refreshToken': refreshToken},
    );

    return response.fold((failure) => Left(failure), (response) async {
      final tokens = AuthTokensModel.fromJson(response.data);
      await _secureStorage.write('token', tokens.token);
      await _secureStorage.write('refreshToken', tokens.refreshToken);
      await _secureStorage.write(
        'tokenExpires',
        tokens.tokenExpires.toString(),
      );
      try {
        await HiveDataSource().updateAccessToken(tokens.token);
        await HiveDataSource().updateRefreshToken(tokens.refreshToken);
        await HiveDataSource().setTokenExpiration(
          tokens.tokenExpires.toString(),
        );
      } catch (_) {}
      try {
        await ApiConfig().setAccessToken(value: tokens.token);
        await ApiConfig().setRefreshToken(refreshToken: tokens.refreshToken);
      } catch (_) {}
      return Right(tokens);
    });
  }

  @override
  Future<Either<Failure, void>> logout() async {
    await _secureStorage.deleteAll();
    try {
      await HiveDataSource().clearAll();
    } catch (_) {}
    try {
      await ApiConfig().clearApiConfig();
    } catch (_) {}
    return const Right(null);
  }

  Future<AuthResponseModel> loginViaLegacyLayer(LoginRequest request) async {
    final response = await ApiLayer.sendRequest(
      ApiEndPoints.userLoginUrl,
      DataRequestMethod.POST,
      (json) => AuthResponseModel.fromJson(json),
      postData: request.toJson(),
    );
    return response as AuthResponseModel;
  }
}
