import 'package:dartz/dartz.dart';

import '../../../../config/services/remote_services/api_endpoints.dart';
import '../../../../config/services/remote_services/errors/failure.dart';
import '../../../../config/services/remote_services/http_service.dart';
import '../models/favorite_category_model.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CategoryHierarchyModel>>> getCategoryHierarchy();
}

class CategoryRepositoryImpl implements CategoryRepository {
  final HttpService _httpService;

  CategoryRepositoryImpl(this._httpService);

  @override
  Future<Either<Failure, List<CategoryHierarchyModel>>>
      getCategoryHierarchy() async {
    final response = await _httpService.get(
      ApiEndPoints.categoryHierarchy,
    );

    return response.fold(
      (l) => Left(l),
      (r) {
        final List<CategoryHierarchyModel> categories = (r.data as List)
            .map((category) => CategoryHierarchyModel.fromJson(category))
            .toList();
        return Right(categories);
      },
    );
  }
}
