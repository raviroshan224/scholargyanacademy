import 'package:dartz/dartz.dart';

import '../../../../config/services/remote_services/api_endpoints.dart';
import '../../../../config/services/remote_services/errors/failure.dart';
import '../../../../config/services/remote_services/http_service.dart';
import '../models/app_info_model.dart';

abstract class AppInfoRepository {
  Future<Either<Failure, AppInfoContent>> fetchAbout();
  Future<Either<Failure, AppInfoContent>> fetchTerms();
  Future<Either<Failure, List<AppFaqItem>>> fetchFaqs();
}

class AppInfoRepositoryImpl implements AppInfoRepository {
  final HttpService _httpService;

  AppInfoRepositoryImpl(this._httpService);

  @override
  Future<Either<Failure, AppInfoContent>> fetchAbout() async {
    final response = await _httpService.get(
      ApiEndPoints.appInfoAbout,
      requiresAuth: false,
    );

    return response.fold(
      (failure) => Left(failure),
      (success) => Right(
        AppInfoContent.fromResponse(
          success.data,
          fallbackTitle: 'About Us',
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, AppInfoContent>> fetchTerms() async {
    final response = await _httpService.get(
      ApiEndPoints.appInfoTerms,
      requiresAuth: false,
    );

    return response.fold(
      (failure) => Left(failure),
      (success) => Right(
        AppInfoContent.fromResponse(
          success.data,
          fallbackTitle: 'Terms & Conditions',
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, List<AppFaqItem>>> fetchFaqs() async {
    final response = await _httpService.get(
      ApiEndPoints.appInfoFaqs,
      requiresAuth: false,
    );

    return response.fold(
      (failure) => Left(failure),
      (success) => Right(AppFaqItem.listFromResponse(success.data)),
    );
  }
}
