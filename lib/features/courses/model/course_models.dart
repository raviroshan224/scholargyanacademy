class PagedMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PagedMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PagedMeta.fromJson(Map<String, dynamic> json) => PagedMeta(
        page: json['page'] ?? 1,
        limit: json['limit'] ?? 10,
        total: json['total'] ?? 0,
        totalPages: json['totalPages'] ?? 0,
        hasNext: json['hasNext'] ?? false,
        hasPrevious: json['hasPrevious'] ?? false,
      );
}

class CourseModel {
  final String id;
  final String courseTitle;
  final String? courseDescription;
  final String? categoryId;
  final String? categoryName;
  final String? courseImageUrl;
  final String? courseIconUrl;
  final int? enrollmentCost;
  final int? discountedPrice;
  final bool? hasOffer;
  final int? durationHours;
  final int? validityDays;
  final String slug;
  final bool isPublished;
  final int? displayOrder;
  final List<String>? tags;
  final bool isSaved;

  CourseModel({
    required this.id,
    required this.courseTitle,
    required this.slug,
    required this.isPublished,
    this.courseDescription,
    this.categoryId,
    this.categoryName,
    this.courseImageUrl,
    this.courseIconUrl,
    this.enrollmentCost,
    this.discountedPrice,
    this.hasOffer,
    this.durationHours,
    this.validityDays,
    this.displayOrder,
    this.tags,
    this.isSaved = false,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] ?? '',
        courseTitle: json['courseTitle'] ?? '',
        courseDescription: json['courseDescription'],
        categoryId: json['categoryId'],
        categoryName: json['categoryName'],
        courseImageUrl: json['courseImageUrl'],
        courseIconUrl: json['courseIconUrl'],
        enrollmentCost: json['enrollmentCost'],
        discountedPrice: json['discountedPrice'],
        hasOffer: json['hasOffer'] is bool
            ? json['hasOffer'] as bool
            : (json['hasOffer']?.toString().toLowerCase() == 'true' ||
                json['hasOffer']?.toString() == '1'),
        durationHours: json['durationHours'],
        validityDays: json['validityDays'],
        slug: json['slug'] ?? '',
        isPublished: json['isPublished'] ?? false,
        displayOrder: json['displayOrder'],
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
        isSaved: json['isSaved'] ?? false,
      );

  CourseModel copyWith({
    String? id,
    String? courseTitle,
    String? courseDescription,
    String? categoryId,
    String? categoryName,
    String? courseImageUrl,
    String? courseIconUrl,
    int? enrollmentCost,
    int? discountedPrice,
    bool? hasOffer,
    int? durationHours,
    int? validityDays,
    String? slug,
    bool? isPublished,
    int? displayOrder,
    List<String>? tags,
    bool? isSaved,
  }) {
    return CourseModel(
      id: id ?? this.id,
      courseTitle: courseTitle ?? this.courseTitle,
      courseDescription: courseDescription ?? this.courseDescription,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      courseImageUrl: courseImageUrl ?? this.courseImageUrl,
      courseIconUrl: courseIconUrl ?? this.courseIconUrl,
      enrollmentCost: enrollmentCost ?? this.enrollmentCost,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      hasOffer: hasOffer ?? this.hasOffer,
      durationHours: durationHours ?? this.durationHours,
      validityDays: validityDays ?? this.validityDays,
      slug: slug ?? this.slug,
      isPublished: isPublished ?? this.isPublished,
      displayOrder: displayOrder ?? this.displayOrder,
      tags: tags ?? this.tags,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class PagedCourses {
  final List<CourseModel> data;
  final PagedMeta meta;

  PagedCourses({required this.data, required this.meta});

  factory PagedCourses.fromJson(Map<String, dynamic> json) => PagedCourses(
        data: (json['data'] as List?)
                ?.map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <CourseModel>[],
        meta: PagedMeta.fromJson(json['meta'] ?? {}),
      );
}

class ChapterModel {
  final String id;
  final int chapterNumber;
  final String chapterTitle;
  final String? chapterDescription;
  final int? displayOrder;

  ChapterModel({
    required this.id,
    required this.chapterNumber,
    required this.chapterTitle,
    this.chapterDescription,
    this.displayOrder,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) => ChapterModel(
        id: json['_id'] ?? json['id'] ?? '',
        chapterNumber: json['chapterNumber'] ?? 0,
        chapterTitle: json['chapterTitle'] ?? '',
        chapterDescription: json['chapterDescription'],
        displayOrder: json['displayOrder'],
      );
}

class SubjectModel {
  final String id;
  final String courseId;
  final String subjectName;
  final String? subjectDescription;
  final int? markWeight;
  final int? displayOrder;
  final bool isActive;
  final List<ChapterModel> chapters;

  SubjectModel({
    required this.id,
    required this.courseId,
    required this.subjectName,
    this.subjectDescription,
    this.markWeight,
    this.displayOrder,
    this.isActive = true,
    this.chapters = const [],
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) => SubjectModel(
        id: json['id'] ?? json['_id'] ?? '',
        courseId: json['courseId'] ?? '',
        subjectName: json['subjectName'] ?? '',
        subjectDescription: json['subjectDescription'],
        markWeight: json['markWeight'],
        displayOrder: json['displayOrder'],
        isActive: json['isActive'] ?? true,
        chapters: (json['chapters'] as List?)
                ?.map((e) => ChapterModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class LecturerModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final List<String> subjectIds;
  final List<String> courseIds;
  final String? subjects; // comma-separated

  LecturerModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.subjectIds = const [],
    this.courseIds = const [],
    this.subjects,
  });

  factory LecturerModel.fromJson(Map<String, dynamic> json) => LecturerModel(
        id: json['id'] ?? '',
        fullName: json['fullName'] ?? '',
        email: json['email'],
        phoneNumber: json['phoneNumber'],
        profileImageUrl: json['profileImageUrl'],
        subjectIds:
            (json['subjectIds'] as List?)?.map((e) => e.toString()).toList() ??
                [],
        courseIds:
            (json['courseIds'] as List?)?.map((e) => e.toString()).toList() ??
                [],
        subjects: json['subjects'],
      );
}

class CourseMaterialModel {
  final String id;
  final String courseId;
  final String? subjectId;
  final String? chapterId;
  final String materialTitle;
  final String? materialDescription;
  final String? materialType;
  final String? downloadUrl;
  final String? fileUrl;
  final String? fileKey;
  final String? fileName;
  final int? fileSize;
  final String? fileExtension;
  final int? downloadCount;
  final int? displayOrder;
  final bool isActive;
  final DateTime? uploadedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourseMaterialModel({
    required this.id,
    required this.courseId,
    this.subjectId,
    this.chapterId,
    required this.materialTitle,
    this.materialDescription,
    this.materialType,
    this.downloadUrl,
    this.fileUrl,
    this.fileKey,
    this.fileName,
    this.fileSize,
    this.fileExtension,
    this.downloadCount,
    this.displayOrder,
    this.isActive = true,
    this.uploadedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseMaterialModel.fromJson(Map<String, dynamic> json) =>
      CourseMaterialModel(
        id: json['id']?.toString() ?? '',
        courseId: json['courseId']?.toString() ?? '',
        subjectId: json['subjectId']?.toString(),
        chapterId: json['chapterId']?.toString(),
        materialTitle: json['materialTitle']?.toString() ?? '',
        materialDescription: json['materialDescription']?.toString(),
        materialType: json['materialType']?.toString(),
        downloadUrl: json['downloadUrl']?.toString() ??
            json['signedUrl']?.toString() ??
            json['url']?.toString(),
        fileUrl: json['fileUrl']?.toString(),
        fileKey: json['fileKey']?.toString(),
        fileName: json['fileName']?.toString(),
        fileSize:
            json['fileSize'] is num ? (json['fileSize'] as num).toInt() : null,
        fileExtension: json['fileExtension']?.toString(),
        downloadCount: json['downloadCount'] is num
            ? (json['downloadCount'] as num).toInt()
            : null,
        displayOrder: json['displayOrder'] is num
            ? (json['displayOrder'] as num).toInt()
            : null,
        isActive: json['isActive'] ?? true,
        uploadedAt: _parseDate(json['uploadedAt']),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class LectureModel {
  final String id;
  final String courseId;
  final String? subjectId;
  final String? chapterId;
  final String name;
  final String? description;
  final String? thumbnailUrl;
  final String? coverImageUrl;
  final int? durationSeconds;
  final int? displayOrder;
  final bool isFree;
  final bool isActive;
  final String? processingStatus;
  final int? viewCount;
  final List<String> lecturerIds;
  final String? lecturerName;
  final String? lecturerProfileImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LectureModel({
    required this.id,
    required this.courseId,
    this.subjectId,
    this.chapterId,
    required this.name,
    this.description,
    this.thumbnailUrl,
    this.coverImageUrl,
    this.durationSeconds,
    this.displayOrder,
    this.isFree = false,
    this.isActive = true,
    this.processingStatus,
    this.viewCount,
    this.lecturerIds = const [],
    this.lecturerName,
    this.lecturerProfileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory LectureModel.fromJson(Map<String, dynamic> json) {
    final lecturer = json['lecturer'] as Map<String, dynamic>?;
    return LectureModel(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      subjectId: json['subjectId']?.toString(),
      chapterId: json['chapterId']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      durationSeconds: json['durationSeconds'] is num
          ? (json['durationSeconds'] as num).toInt()
          : null,
      displayOrder: json['displayOrder'] is num
          ? (json['displayOrder'] as num).toInt()
          : null,
      isFree: json['isFree'] ?? json['is_free'] ?? false,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      processingStatus: json['processingStatus']?.toString(),
      viewCount:
          json['viewCount'] is num ? (json['viewCount'] as num).toInt() : null,
      lecturerIds:
          (json['lecturerIds'] as List?)?.map((e) => e.toString()).toList() ??
              const <String>[],
      lecturerName: lecturer?['fullName']?.toString(),
      lecturerProfileImageUrl: lecturer?['profileImageUrl']?.toString(),
      createdAt: CourseMaterialModel._parseDate(json['createdAt']),
      updatedAt: CourseMaterialModel._parseDate(json['updatedAt']),
    );
  }
}

class CourseClassModel {
  final String id;
  final String title;
  final String? description;
  final DateTime? startTime;
  final String? durationLabel;
  final int? durationMinutes;
  final Map<String, dynamic> raw;

  CourseClassModel({
    required this.id,
    required this.title,
    this.description,
    this.startTime,
    this.durationLabel,
    this.durationMinutes,
    required this.raw,
  });

  factory CourseClassModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final start = _coerceToDateTime(
      map['startTime'] ??
          map['startsAt'] ??
          map['startAt'] ??
          map['scheduledAt'],
    );
    final durationMinutes = _coerceToInt(
      map['durationMinutes'] ?? map['duration'] ?? map['durationInMinutes'],
    );
    final durationText = map['durationText']?.toString() ??
        map['durationLabel']?.toString() ??
        (durationMinutes != null ? '${durationMinutes} min' : null);

    return CourseClassModel(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? map['name']?.toString() ?? 'Class',
      description: map['description']?.toString(),
      startTime: start,
      durationLabel: (durationText != null && durationText.isNotEmpty)
          ? durationText
          : null,
      durationMinutes: durationMinutes,
      raw: map,
    );
  }
}

class MockTestModel {
  final String id;
  final String? courseId;
  final String? courseName;
  final String title;
  final String? description;
  final String? instructions;
  final String? testType;
  final String? subjectId;
  final String? subjectName;
  final int? numberOfQuestions;
  final int? durationMinutes;
  final int? cost;
  final int? attemptsAllowed;
  final String? status;
  final Map<String, dynamic> raw;

  MockTestModel({
    required this.id,
    required this.title,
    required this.raw,
    this.courseId,
    this.courseName,
    this.description,
    this.instructions,
    this.testType,
    this.subjectId,
    this.subjectName,
    this.numberOfQuestions,
    this.durationMinutes,
    this.cost,
    this.attemptsAllowed,
    this.status,
  });

  factory MockTestModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return MockTestModel(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      courseId: map['courseId']?.toString(),
      courseName: map['courseName']?.toString(),
      title: map['title']?.toString() ?? map['name']?.toString() ?? 'Mock Test',
      description: map['description']?.toString(),
      instructions: map['instructions']?.toString(),
      testType: map['testType']?.toString(),
      subjectId: map['subjectId']?.toString(),
      subjectName: map['subjectName']?.toString(),
      numberOfQuestions: _coerceToInt(
        map['numberOfQuestions'] ??
            map['totalQuestions'] ??
            map['questionCount'],
      ),
      durationMinutes: _coerceToInt(
        map['durationMinutes'] ?? map['duration'] ?? map['durationInMinutes'],
      ),
      cost: _coerceToInt(map['cost']),
      attemptsAllowed: _coerceToInt(map['attemptsAllowed']),
      status: map['status']?.toString(),
      raw: map,
    );
  }

  List<Map<String, dynamic>> get subjectDistribution {
    return _mapList(raw['subjectDistribution'] ?? raw['distribution']);
  }

  int? get resolvedQuestionCount {
    if (numberOfQuestions != null) {
      return numberOfQuestions;
    }
    final distribution = subjectDistribution;
    if (distribution.isNotEmpty) {
      final total = distribution.fold<int>(0, (sum, item) {
        final value = _coerceToInt(item['numberOfQuestions'] ?? item['count']);
        return sum + (value ?? 0);
      });
      if (total > 0) return total;
    }
    final questions = raw['questions'];
    if (questions is List) {
      return questions.length;
    }
    return null;
  }

  String? get durationLabel {
    final label = raw['durationText']?.toString();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    if (durationMinutes != null) {
      return '${durationMinutes} min';
    }
    return null;
  }
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

int? _coerceToInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _coerceToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
