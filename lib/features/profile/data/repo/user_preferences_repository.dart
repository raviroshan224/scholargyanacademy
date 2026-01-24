import 'package:dartz/dartz.dart';

import '../../../../config/services/remote_services/api_endpoints.dart';
import '../../../../config/services/remote_services/errors/failure.dart';
import '../../../../config/services/remote_services/http_service.dart';
import '../models/favorite_category_model.dart';

abstract class UserPreferencesRepository {
  Future<Either<Failure, List<FavoriteCategoryModel>>> getFavoriteCategories();
  Future<Either<Failure, void>> updateFavoriteCategories(List<String> ids);
}

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  final HttpService _httpService;

  UserPreferencesRepositoryImpl(this._httpService);

  @override
  Future<Either<Failure, List<FavoriteCategoryModel>>> getFavoriteCategories() async {
    final response = await _httpService.get(
      ApiEndPoints.favoriteCategories,
      requiresAuth: true,
    );

    return response.fold(
      (l) => Left(l),
      (r) {
        final List<FavoriteCategoryModel> categories =
            (r.data['favoriteCategories'] as List)
                .map((category) => FavoriteCategoryModel.fromJson(category))
                .toList();
        return Right(categories);
      },
    );
  }

  @override
  Future<Either<Failure, void>> updateFavoriteCategories(
      List<String> ids) async {
    final response = await _httpService.put(
      ApiEndPoints.favoriteCategories,
      data: {'categoryIds': ids},
      requiresAuth: true,
    );

    return response.fold(
      (l) {
        if (l.message.contains('422')) {
          return Left(Failure(message: 'A parent category cannot be selected'));
        }
        return Left(l);
      },
      (r) => const Right(null),
    );
  }
}
