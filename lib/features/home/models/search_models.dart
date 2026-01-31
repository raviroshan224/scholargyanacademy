/// Models for the homepage search API response.
/// Endpoint: GET /api/v1/homepage/search

class HomeSearchResponse {
  const HomeSearchResponse({
    this.courses = const <SearchCourse>[],
    this.mockTests = const <SearchMockTest>[],
    this.totalCourses = 0,
    this.totalMockTests = 0,
  });

  final List<SearchCourse> courses;
  final List<SearchMockTest> mockTests;
  final int totalCourses;
  final int totalMockTests;

  bool get isEmpty => courses.isEmpty && mockTests.isEmpty;
  bool get isNotEmpty => !isEmpty;

  factory HomeSearchResponse.fromJson(Map<String, dynamic> json) {
    return HomeSearchResponse(
      courses: _decodeList(json['courses'], SearchCourse.fromJson),
      mockTests: _decodeList(json['mockTests'], SearchMockTest.fromJson),
      totalCourses: _toInt(json['totalCourses']) ?? 0,
      totalMockTests: _toInt(json['totalMockTests']) ?? 0,
    );
  }
}

/// Course item returned by the search API.
class SearchCourse {
  const SearchCourse({
    this.id,
    this.courseTitle,
    this.courseImageUrl,
    this.categoryName,
    this.enrollmentCost,
    this.discountedPrice,
    this.hasOffer,
    this.durationHours,
    this.relevanceScore,
  });

  final String? id;
  final String? courseTitle;
  final String? courseImageUrl;
  final String? categoryName;
  final int? enrollmentCost;
  final int? discountedPrice;
  final bool? hasOffer;
  final int? durationHours;
  final double? relevanceScore;

  factory SearchCourse.fromJson(Map<String, dynamic> json) {
    return SearchCourse(
      id: json['id']?.toString(),
      courseTitle: json['courseTitle']?.toString(),
      courseImageUrl: json['courseImageUrl']?.toString(),
      categoryName: json['categoryName']?.toString(),
      enrollmentCost: _toInt(json['enrollmentCost']),
      discountedPrice: _toInt(json['discountedPrice']),
      hasOffer: json['hasOffer'] is bool
          ? json['hasOffer'] as bool
          : (json['hasOffer']?.toString().toLowerCase() == 'true' ||
              json['hasOffer']?.toString() == '1'),
      durationHours: _toInt(json['durationHours']),
      relevanceScore: _toDouble(json['relevanceScore']),
    );
  }
}

/// Mock test item returned by the search API.
class SearchMockTest {
  const SearchMockTest({
    this.id,
    this.courseId,
    this.title,
    this.description,
    this.cost,
    this.durationMinutes,
    this.relevanceScore,
  });

  final String? id;
  final String? courseId;
  final String? title;
  final String? description;
  final double? cost;
  final int? durationMinutes;
  final double? relevanceScore;

  factory SearchMockTest.fromJson(Map<String, dynamic> json) {
    return SearchMockTest(
      id: json['id']?.toString(),
      courseId: json['courseId']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      cost: _toDouble(json['cost']),
      durationMinutes: _toInt(json['durationMinutes']),
      relevanceScore: _toDouble(json['relevanceScore']),
    );
  }
}

// Helper functions (same pattern as homepage_models.dart)

List<T> _decodeList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) factoryFn,
) {
  final results = <T>[];
  if (data is List) {
    for (final dynamic item in data) {
      Map<String, dynamic>? map;
      if (item is Map<String, dynamic>) {
        map = item;
      } else if (item is Map) {
        map = Map<String, dynamic>.from(item);
      }
      if (map != null) {
        results.add(factoryFn(map));
      }
    }
  }
  return results;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}
