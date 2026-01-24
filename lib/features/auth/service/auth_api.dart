import 'package:either_dart/either.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/api_endpoints.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/errors/failure.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/http_service.dart';
import 'package:scholarsgyanacademy/features/auth/model/auth_models.dart';
import 'package:scholarsgyanacademy/features/auth/model/email_verification_request.dart';
import 'package:scholarsgyanacademy/features/auth/model/login_request.dart';
import 'package:scholarsgyanacademy/features/auth/model/register_request.dart';

class AuthApi {
  final HttpService http;

  AuthApi(this.http);

  Future<Either<Failure, AuthResponseModel>> login(LoginRequest request) async {
    final res = await http.post(
      ApiEndPoints.userLoginUrl,
      data: request.toJson(),
      requiresAuth: false,
    );

    return res.fold((l) => Left(l), (r) {
      final data = r.data as Map<String, dynamic>;
      return Right(AuthResponseModel.fromJson(data));
    });
  }

  Future<Either<Failure, void>> register(RegisterRequest request) async {
    final res = await http.post(
      ApiEndPoints.userSignUpUrl,
      data: request.toJson(),
      requiresAuth: false,
    );

    return res.fold((l) => Left(l), (r) => const Right(null));
  }

  Future<Either<Failure, void>> sendEmailVerificationOtp(
    SendEmailVerificationRequest request,
  ) async {
    final res = await http.post(
      ApiEndPoints.sendEmailVerificationOtpUrl,
      data: request.toJson(),
      requiresAuth: false,
    );

    return res.fold((l) => Left(l), (r) => const Right(null));
  }

  Future<Either<Failure, void>> verifyEmailOtp(
    VerifyEmailOtpRequest request,
  ) async {
    final res = await http.post(
      ApiEndPoints.verifyEmailOtpUrl,
      data: request.toJson(),
      requiresAuth: false,
    );

    return res.fold((l) => Left(l), (r) => const Right(null));
  }

  Future<Either<Failure, void>> forgotPassword(String email) async {
    final res = await http.post(
      ApiEndPoints.forgetPassword,
      data: {'email': email},
      requiresAuth: false,
    );
    return res.fold((l) => Left(l), (r) => const Right(null));
  }

  Future<Either<Failure, void>> verifyOtp(Map<String, dynamic> body) async {
    final res = await http.post(
      ApiEndPoints.verifyOTP,
      data: body,
      requiresAuth: false,
    );
    return res.fold((l) => Left(l), (r) => const Right(null));
  }

  Future<Either<Failure, void>> resetPassword(Map<String, dynamic> body) async {
    final res = await http.post(
      ApiEndPoints.resetPassword,
      data: body,
      requiresAuth: false,
    );
    return res.fold((l) => Left(l), (r) => const Right(null));
  }
}
