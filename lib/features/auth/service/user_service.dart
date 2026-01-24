import 'dart:io';

import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/api_endpoints.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/errors/failure.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/http_service.dart';
import 'package:scholarsgyanacademy/features/auth/model/auth_models.dart';

abstract class UserService {
  Future<Either<Failure, UserModel>> getMe();
  Future<Either<Failure, UserModel>> updateProfile(ProfileUpdateModel profile);
  Future<Either<Failure, void>> updatePassword(
    PasswordUpdateModel passwordUpdate,
  );
  Future<Either<Failure, UserModel>> uploadProfilePicture(File image);
}

class UserServiceImpl implements UserService {
  final HttpService _httpService;

  UserServiceImpl(this._httpService);

  @override
  Future<Either<Failure, UserModel>> getMe() async {
    final response = await _httpService.get(
      ApiEndPoints.getCurrentUser,
      requiresAuth: true,
    );
    return response.fold(
      (failure) => Left(failure),
      (response) => Right(UserModel.fromJson(response.data)),
    );
  }

  @override
  Future<Either<Failure, UserModel>> updateProfile(
    ProfileUpdateModel profile,
  ) async {
    final response = await _httpService.patch(
      ApiEndPoints.updateProfile,
      data: profile.toJson(),
      requiresAuth: true,
    );
    return response.fold(
      (failure) => Left(failure),
      (response) => Right(UserModel.fromJson(response.data)),
    );
  }

  @override
  Future<Either<Failure, void>> updatePassword(
    PasswordUpdateModel passwordUpdate,
  ) async {
    final response = await _httpService.patch(
      ApiEndPoints.changePassword,
      data: passwordUpdate.toJson(),
      requiresAuth: true,
    );
    return response.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, UserModel>> uploadProfilePicture(File image) async {
    final fileName = image.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path, filename: fileName),
    });
    final response = await _httpService.post(
      ApiEndPoints.uploadProfilePicture,
      formData: formData,
      requiresAuth: true,
    );
    return response.fold(
      (failure) => Left(failure),
      (response) => Right(UserModel.fromJson(response.data)),
    );
  }
}
