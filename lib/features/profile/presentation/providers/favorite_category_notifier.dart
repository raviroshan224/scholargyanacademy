import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/favorite_category_model.dart';
import '../../data/repo/user_preferences_repository.dart';

class FavoriteCategoryNotifier extends StateNotifier<FavoriteCategoryState> {
  final UserPreferencesRepository _userPreferencesRepository;
  final Future<List<CategoryHierarchyModel>> _categoryHierarchyFuture;
  final Future<List<FavoriteCategoryModel>> _favoriteCategoriesFuture;

  FavoriteCategoryNotifier(
    this._userPreferencesRepository,
    this._categoryHierarchyFuture,
    this._favoriteCategoriesFuture,
  ) : super(FavoriteCategoryState.initial()) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    state = state.copyWith(isLoading: true);
    try {
      final categoryHierarchy = await _categoryHierarchyFuture;
      final favoriteCategories = await _favoriteCategoriesFuture;

      final favoriteCategoryIds =
          favoriteCategories.map((fav) => fav.id).toSet();

      for (var parent in categoryHierarchy) {
        for (var child in parent.childCategories) {
          if (favoriteCategoryIds.contains(child.id)) {
            child.isSelected = true;
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        categoryHierarchy: categoryHierarchy,
        selectedCategoryIds: favoriteCategoryIds.toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleCategory(String categoryId) {
    final selectedIds = List<String>.from(state.selectedCategoryIds);
    if (selectedIds.contains(categoryId)) {
      selectedIds.remove(categoryId);
    } else {
      selectedIds.add(categoryId);
    }

    final updatedHierarchy = state.categoryHierarchy.map((parent) {
      parent.childCategories.map((child) {
        if (child.id == categoryId) {
          child.isSelected = !child.isSelected;
        }
        return child;
      }).toList();
      return parent;
    }).toList();

    state = state.copyWith(
      selectedCategoryIds: selectedIds,
      categoryHierarchy: updatedHierarchy,
    );
  }

  Future<void> updateFavoriteCategories() async {
    state = state.copyWith(isUpdating: true, error: null);
    final result = await _userPreferencesRepository
        .updateFavoriteCategories(state.selectedCategoryIds);
    result.fold(
      (failure) =>
          state = state.copyWith(isUpdating: false, error: failure.message),
      (_) =>
          state = state.copyWith(isUpdating: false, isUpdateSuccessful: true),
    );
  }
}

class FavoriteCategoryState {
  final bool isLoading;
  final bool isUpdating;
  final bool isUpdateSuccessful;
  final String? error;
  final List<CategoryHierarchyModel> categoryHierarchy;
  final List<String> selectedCategoryIds;

  FavoriteCategoryState({
    required this.isLoading,
    required this.isUpdating,
    required this.isUpdateSuccessful,
    this.error,
    required this.categoryHierarchy,
    required this.selectedCategoryIds,
  });

  factory FavoriteCategoryState.initial() {
    return FavoriteCategoryState(
      isLoading: false,
      isUpdating: false,
      isUpdateSuccessful: false,
      error: null,
      categoryHierarchy: [],
      selectedCategoryIds: [],
    );
  }

  FavoriteCategoryState copyWith({
    bool? isLoading,
    bool? isUpdating,
    bool? isUpdateSuccessful,
    String? error,
    List<CategoryHierarchyModel>? categoryHierarchy,
    List<String>? selectedCategoryIds,
  }) {
    return FavoriteCategoryState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      isUpdateSuccessful: isUpdateSuccessful ?? this.isUpdateSuccessful,
      error: error,
      categoryHierarchy: categoryHierarchy ?? this.categoryHierarchy,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
    );
  }
}
