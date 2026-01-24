import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../config/services/remote_services/http_service_provider.dart';
import '../../data/models/favorite_category_model.dart';
import '../../data/repo/category_repository.dart';
import '../../data/repo/user_preferences_repository.dart';
import 'favorite_category_notifier.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((Ref ref) {
  final httpService = ref.watch(httpServiceProvider);
  return CategoryRepositoryImpl(httpService);
});

final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((Ref ref) {
  final httpService = ref.watch(httpServiceProvider);
  return UserPreferencesRepositoryImpl(httpService);
});

final categoryHierarchyProvider =
    FutureProvider<List<CategoryHierarchyModel>>((Ref ref) async {
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  final result = await categoryRepo.getCategoryHierarchy();
  return result.fold(
    (failure) => throw failure,
    (categories) => categories,
  );
});

final favoriteCategoriesProvider =
    FutureProvider<List<FavoriteCategoryModel>>((Ref ref) async {
  final userPreferencesRepo = ref.watch(userPreferencesRepositoryProvider);
  final result = await userPreferencesRepo.getFavoriteCategories();
  return result.fold(
    (failure) => throw failure,
    (categories) => categories,
  );
});

final favoriteCategoryNotifierProvider =
    StateNotifierProvider<FavoriteCategoryNotifier, FavoriteCategoryState>(
        (Ref ref) {
  return FavoriteCategoryNotifier(
    ref.watch(userPreferencesRepositoryProvider),
    ref.watch(categoryHierarchyProvider.future),
    ref.watch(favoriteCategoriesProvider.future),
  );
});
