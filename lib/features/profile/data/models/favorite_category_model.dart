class CategoryHierarchyModel {
  final ParentCategoryModel parentCategory;
  final List<ChildCategoryModel> childCategories;

  CategoryHierarchyModel({
    required this.parentCategory,
    required this.childCategories,
  });

  factory CategoryHierarchyModel.fromJson(Map<String, dynamic> json) {
    return CategoryHierarchyModel(
      parentCategory: ParentCategoryModel.fromJson(json['parentCategory']),
      childCategories: List<ChildCategoryModel>.from(
        json['childCategories'].map((x) => ChildCategoryModel.fromJson(x)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentCategory': parentCategory.toJson(),
      'childCategories':
          List<dynamic>.from(childCategories.map((x) => x.toJson())),
    };
  }
}

class ParentCategoryModel {
  final String id;
  final String categoryName;
  final String? categoryImageUrl;

  ParentCategoryModel(
      {required this.id, required this.categoryName, this.categoryImageUrl});

  factory ParentCategoryModel.fromJson(Map<String, dynamic> json) {
    return ParentCategoryModel(
      id: json['id'],
      categoryName: json['categoryName'],
      categoryImageUrl: json['categoryImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
    };
  }
}

class ChildCategoryModel {
  final String id;
  final String categoryName;
  final String? categoryImageUrl;
  bool isSelected;

  ChildCategoryModel({
    required this.id,
    required this.categoryName,
    this.categoryImageUrl,
    this.isSelected = false,
  });

  factory ChildCategoryModel.fromJson(Map<String, dynamic> json) {
    return ChildCategoryModel(
      id: json['id'],
      categoryName: json['categoryName'],
      categoryImageUrl: json['categoryImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
      'categoryImageUrl': categoryImageUrl,
    };
  }
}

class FavoriteCategoryModel {
  final String id;
  final String categoryName;
  final String? categoryImageUrl;

  FavoriteCategoryModel({
    required this.id,
    required this.categoryName,
    this.categoryImageUrl,
  });

  factory FavoriteCategoryModel.fromJson(Map<String, dynamic> json) {
    return FavoriteCategoryModel(
      id: json['id'],
      categoryName: json['categoryName'],
      categoryImageUrl: json['categoryImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
      'categoryImageUrl': categoryImageUrl,
    };
  }
}
