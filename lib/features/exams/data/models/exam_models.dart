class ExamListResponse {
  const ExamListResponse({
    required this.items,
    this.meta,
  });

  final List<ExamSummary> items;
  final ExamListMeta? meta;

  factory ExamListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'];
    final metaJson = json['meta'];
    return ExamListResponse(
      items: _mapToList(dataList, ExamSummary.fromJson),
      meta: metaJson is Map<String, dynamic>
          ? ExamListMeta.fromJson(metaJson)
          : metaJson is Map
              ? ExamListMeta.fromJson(Map<String, dynamic>.from(metaJson))
              : null,
    );
  }
}

class ExamListMeta {
  const ExamListMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  factory ExamListMeta.fromJson(Map<String, dynamic> json) {
    return ExamListMeta(
      page: _asInt(json['page']) ?? 1,
      limit: _asInt(json['limit']) ?? 10,
      total: _asInt(json['total']) ?? 0,
      totalPages: _asInt(json['totalPages']) ?? 1,
      hasNext: _asBool(json['hasNext']) ?? false,
      hasPrevious: _asBool(json['hasPrevious']) ?? false,
    );
  }
}

class ExamSummary {
  const ExamSummary({
    required this.id,
    required this.title,
    this.category,
    this.validityDays,
    this.description,
    this.examImageUrl,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.courses = const <String>[],
    this.courseDetails = const <ExamCourseInfo>[],
    this.totalCourses,
  });

  final String id;
  final String title;
  final String? category;
  final int? validityDays;
  final String? description;
  final String? examImageUrl;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> courses;
  final List<ExamCourseInfo> courseDetails;
  final int? totalCourses;

  factory ExamSummary.fromJson(Map<String, dynamic> json) {
    return ExamSummary(
      id: _asString(json['id']) ?? '',
      title: _asString(json['title']) ?? '',
      category: _asString(json['category']),
      validityDays: _asInt(json['validityDays']),
      description: _asString(json['description']),
      examImageUrl: _asString(json['examImageUrl']),
      status: _asString(json['status']),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
      courses: _mapToStringList(json['courses']),
      courseDetails: _mapToList(json['courseDetails'], ExamCourseInfo.fromJson),
      totalCourses: _asInt(json['totalCourses']),
    );
  }
}

class ExamDetail {
  const ExamDetail({
    required this.id,
    required this.title,
    this.category,
    this.validityDays,
    this.description,
    this.examImageUrl,
    this.examImageKey,
    this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.courses = const <String>[],
    this.courseDetails = const <ExamCourseInfo>[],
    this.totalCourses,
  });

  final String id;
  final String title;
  final String? category;
  final int? validityDays;
  final String? description;
  final String? examImageUrl;
  final String? examImageKey;
  final String? status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> courses;
  final List<ExamCourseInfo> courseDetails;
  final int? totalCourses;

  factory ExamDetail.fromJson(Map<String, dynamic> json) {
    return ExamDetail(
      id: _asString(json['id']) ?? '',
      title: _asString(json['title']) ?? '',
      category: _asString(json['category']),
      validityDays: _asInt(json['validityDays']),
      description: _asString(json['description']),
      examImageUrl: _asString(json['examImageUrl']),
      examImageKey: _asString(json['examImageKey']),
      status: _asString(json['status']),
      createdBy: _asString(json['createdBy']),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
      courses: _mapToStringList(json['courses']),
      courseDetails: _mapToList(json['courseDetails'], ExamCourseInfo.fromJson),
      totalCourses: _asInt(json['totalCourses']),
    );
  }
}

class ExamCourseInfo {
  const ExamCourseInfo({
    required this.id,
    required this.title,
    this.thumbnail,
    this.classCount,
    this.description,
  });

  final String id;
  final String title;
  final String? thumbnail;
  final int? classCount;
  final String? description;

  factory ExamCourseInfo.fromJson(Map<String, dynamic> json) {
    return ExamCourseInfo(
      id: _asString(json['id']) ?? '',
      title: _asString(json['title']) ?? '',
      thumbnail: _asString(json['thumbnail']),
      classCount: _asInt(json['classCount']),
      description: _asString(json['description']),
    );
  }
}

List<T> _mapToList<T>(
  dynamic source,
  T Function(Map<String, dynamic> json) parser,
) {
  final result = <T>[];

  if (source is List) {
    for (final entry in source) {
      Map<String, dynamic>? map;
      if (entry is Map<String, dynamic>) {
        map = entry;
      } else if (entry is Map) {
        map = Map<String, dynamic>.from(entry);
      }
      if (map != null) {
        result.add(parser(map));
      }
    }
    return result;
  }

  if (source is Map<String, dynamic>) {
    result.add(parser(source));
    return result;
  }

  if (source is Map) {
    result.add(parser(Map<String, dynamic>.from(source)));
    return result;
  }

  return result;
}

List<String> _mapToStringList(dynamic source) {
  if (source is List) {
    final result = <String>[];
    for (final value in source) {
      final text = _asString(value);
      if (text != null) {
        result.add(text);
      }
    }
    return result;
  }

  final single = _asString(source);
  if (single != null) {
    return <String>[single];
  }

  return const <String>[];
}

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().toLowerCase();
  if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == 'no' || normalized == '0') {
    return false;
  }
  return null;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
