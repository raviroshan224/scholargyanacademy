class HomepageResponse {
  const HomepageResponse({
    this.userProfile,
    this.preferredCategories = const <Category>[],
    this.recommendedExams = const <Exam>[],
    this.recommendedCourses = const <Course>[],
    this.bannerCourses = const <Course>[],
    this.latestOngoingCourse,
    this.liveClasses = const <LiveClass>[],
    this.upcomingExam,
    this.topCategoryWithCourses,
  });

  final UserProfile? userProfile;
  final List<Category> preferredCategories;
  final List<Exam> recommendedExams;
  final List<Course> recommendedCourses;
  final List<Course> bannerCourses;
  final LatestOngoingCourse? latestOngoingCourse;
  final List<LiveClass> liveClasses;
  final UpcomingExam? upcomingExam;
  final TopCategoryWithCourses? topCategoryWithCourses;

  factory HomepageResponse.fromJson(Map<String, dynamic> json) {
    return HomepageResponse(
      userProfile: _decodeObject(json['userProfile'], UserProfile.fromJson),
      preferredCategories:
          _decodeList(json['preferredCategories'], Category.fromJson),
      recommendedExams: _decodeList(json['recommendedExams'], Exam.fromJson),
      recommendedCourses:
          _decodeList(json['recommendedCourses'], Course.fromJson),
      bannerCourses: _decodeList(json['bannerCourses'], Course.fromJson),
      latestOngoingCourse: _decodeObject(
        json['latestOngoingCourse'],
        LatestOngoingCourse.fromJson,
      ),
      liveClasses: _decodeList(json['liveClasses'], LiveClass.fromJson),
      upcomingExam: _decodeObject(json['upcomingExam'], UpcomingExam.fromJson),
      topCategoryWithCourses: _decodeObject(
        json['topCategoryWithCourses'],
        TopCategoryWithCourses.fromJson,
      ),
    );
  }
}

class UserProfile {
  const UserProfile({this.fullName, this.photo});

  final String? fullName;
  final String? photo;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String? resolvedPhoto;
    final raw = json['photo'];
    if (raw is String) {
      resolvedPhoto = raw;
    } else if (raw is Map) {
      final map = Map<String, dynamic>.from(raw as Map);
      // Try common keys
      final candidates = [
        map['url'],
        map['path'],
        map['photoUrl'],
        map['secure_url'],
      ].whereType<String>().toList();
      for (final c in candidates) {
        if (c.trim().isNotEmpty) {
          resolvedPhoto = c;
          break;
        }
      }
    }

    return UserProfile(
      fullName: json['fullName']?.toString(),
      photo: resolvedPhoto,
    );
  }
}

class Category {
  const Category({
    this.id,
    this.categoryName,
    this.categoryImageUrl,
  });

  final String? id;
  final String? categoryName;
  final String? categoryImageUrl;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id']?.toString(),
        categoryName: json['categoryName']?.toString(),
        categoryImageUrl: json['categoryImageUrl']?.toString(),
      );
}

class Exam {
  const Exam({
    this.id,
    this.title,
    this.examImageUrl,
    this.category,
    this.validityDays,
    this.daysUntilExam,
    this.examDate,
  });

  final String? id;
  final String? title;
  final String? examImageUrl;
  final String? category;
  final int? validityDays;
  final int? daysUntilExam;
  final DateTime? examDate;

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id']?.toString(),
        title: json['title']?.toString(),
        examImageUrl: json['examImageUrl']?.toString(),
        category: json['category']?.toString(),
        validityDays: _toInt(json['validityDays']),
        daysUntilExam: _toInt(json['daysUntilExam']),
        examDate: _toDate(json['examDate']),
      );
}

class Course {
  const Course({
    this.id,
    this.courseTitle,
    this.courseImageUrl,
    this.courseIconUrl,
    this.enrollmentCost,
    this.discountedPrice,
    this.hasOffer,
    this.durationHours,
    this.isSaved,
    this.categoryName,
    this.validityDays,
  });

  final String? id;
  final String? courseTitle;
  final String? courseImageUrl;
  final String? courseIconUrl;
  final int? enrollmentCost;
  final int? discountedPrice;
  final bool? hasOffer;
  final int? durationHours;
  final bool? isSaved;
  final String? categoryName;
  final int? validityDays;

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id']?.toString(),
        courseTitle: json['courseTitle']?.toString(),
        courseImageUrl: json['courseImageUrl']?.toString(),
        courseIconUrl: json['courseIconUrl']?.toString(),
        enrollmentCost: _toInt(json['enrollmentCost']),
        discountedPrice: _toInt(json['discountedPrice']),
        hasOffer: json['hasOffer'] is bool
            ? json['hasOffer'] as bool
            : (json['hasOffer']?.toString().toLowerCase() == 'true' ||
                json['hasOffer']?.toString() == '1'),
        durationHours: _toInt(json['durationHours']),
        isSaved: json['isSaved'] is bool
            ? json['isSaved'] as bool
            : json['isSaved']?.toString().toLowerCase() == 'true',
        categoryName: json['categoryName']?.toString(),
        validityDays: _toInt(json['validityDays']),
      );
}

class LatestOngoingCourse {
  const LatestOngoingCourse({
    this.id,
    this.courseTitle,
    this.courseImageUrl,
    this.progressPercentage,
    this.completedLectures,
    this.totalLectures,
    this.lastAccessedLectureId,
    this.lastAccessedLectureTitle,
    this.lastAccessedLectureThumbnail,
    this.lastWatchedPositionSeconds,
  });

  final String? id;
  final String? courseTitle;
  final String? courseImageUrl;
  final double? progressPercentage;
  final int? completedLectures;
  final int? totalLectures;
  final String? lastAccessedLectureId;
  final String? lastAccessedLectureTitle;
  final String? lastAccessedLectureThumbnail;
  final int? lastWatchedPositionSeconds;

  factory LatestOngoingCourse.fromJson(Map<String, dynamic> json) =>
      LatestOngoingCourse(
        id: json['id']?.toString(),
        courseTitle: json['courseTitle']?.toString(),
        courseImageUrl: json['courseImageUrl']?.toString(),
        progressPercentage: _toDouble(json['progressPercentage']),
        completedLectures: _toInt(json['completedLectures']),
        totalLectures: _toInt(json['totalLectures']),
        lastAccessedLectureId: json['lastAccessedLectureId']?.toString(),
        lastAccessedLectureTitle: json['lastAccessedLectureTitle']?.toString(),
        lastAccessedLectureThumbnail: json['lastAccessedLectureThumbnail']?.toString(),
        lastWatchedPositionSeconds: _toInt(json['lastWatchedPositionSeconds']),
      );
}

class LiveClass {
  const LiveClass({
    this.id,
    this.title,
    this.scheduledAt,
    this.thumbnailUrl,
  });

  final String? id;
  final String? title;
  final DateTime? scheduledAt;
  final String? thumbnailUrl;

  factory LiveClass.fromJson(Map<String, dynamic> json) => LiveClass(
        id: json['id']?.toString(),
        title: json['title']?.toString(),
        scheduledAt: _toDateTime(json['scheduledAt']),
        thumbnailUrl: json['thumbnailUrl']?.toString(),
      );
}

class UpcomingExam {
  const UpcomingExam({
    this.id,
    this.title,
    this.examImageUrl,
    this.examDate,
    this.daysUntilExam,
  });

  final String? id;
  final String? title;
  final String? examImageUrl;
  final DateTime? examDate;
  final int? daysUntilExam;

  factory UpcomingExam.fromJson(Map<String, dynamic> json) => UpcomingExam(
        id: json['id']?.toString(),
        title: json['title']?.toString(),
        examImageUrl: json['examImageUrl']?.toString(),
        examDate: _toDate(json['examDate']),
        daysUntilExam: _toInt(json['daysUntilExam']),
      );
}

class TopCategoryWithCourses {
  const TopCategoryWithCourses({
    this.categoryId,
    this.categoryName,
    this.categoryImageUrl,
    this.courses = const <Course>[],
  });

  final String? categoryId;
  final String? categoryName;
  final String? categoryImageUrl;
  final List<Course> courses;

  factory TopCategoryWithCourses.fromJson(Map<String, dynamic> json) =>
      TopCategoryWithCourses(
        categoryId: json['categoryId']?.toString(),
        categoryName: json['categoryName']?.toString(),
        categoryImageUrl: json['categoryImageUrl']?.toString(),
        courses: _decodeList(json['courses'], Course.fromJson),
      );
}

class UpdateCategoryRequest {
  UpdateCategoryRequest({required this.categoryId});

  final String categoryId;

  Map<String, dynamic> toJson() => {'categoryId': categoryId};
}

class UpdateCategoryResponse {
  const UpdateCategoryResponse({this.message, this.categoryId});

  final String? message;
  final String? categoryId;

  factory UpdateCategoryResponse.fromJson(Map<String, dynamic> json) =>
      UpdateCategoryResponse(
        message: json['message']?.toString(),
        categoryId: json['categoryId']?.toString(),
      );
}

T? _decodeObject<T>(
  dynamic data,
  T Function(Map<String, dynamic>) factoryFn,
) {
  if (data == null) {
    return null;
  }
  if (data is Map<String, dynamic>) {
    return factoryFn(data);
  }
  if (data is Map) {
    return factoryFn(Map<String, dynamic>.from(data));
  }
  return null;
}

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

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

DateTime? _toDateTime(dynamic value) {
  return _toDate(value);
}
