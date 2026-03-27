class ListmentProgress {
  final int completedLecturesCount;
  final int totalLectures;
  final double progressPercentage;
  final String? lastAccessedAt;
  final String? lastAccessedLectureId;

  ListmentProgress({
    required this.completedLecturesCount,
    required this.totalLectures,
    required this.progressPercentage,
    this.lastAccessedAt,
    this.lastAccessedLectureId,
  });

  factory ListmentProgress.fromJson(Map<String, dynamic> json) =>
      ListmentProgress(
        completedLecturesCount: json['completedLecturesCount'] ?? 0,
        totalLectures: json['totalLectures'] ?? 0,
        progressPercentage: (json['progressPercentage'] is num)
            ? (json['progressPercentage'] as num).toDouble()
            : 0.0,
        lastAccessedAt: json['lastAccessedAt']?.toString(),
        lastAccessedLectureId: json['lastAccessedLectureId']?.toString(),
      );
}

class ListmentCertificate {
  final bool issued;
  final String? issuedAt;
  final String? certificateUrl;
  final String? certificateNumber;

  ListmentCertificate({
    required this.issued,
    this.issuedAt,
    this.certificateUrl,
    this.certificateNumber,
  });

  factory ListmentCertificate.fromJson(Map<String, dynamic> json) =>
      ListmentCertificate(
        issued: json['issued'] ?? false,
        issuedAt: json['issuedAt']?.toString(),
        certificateUrl: json['certificateUrl']?.toString(),
        certificateNumber: json['certificateNumber']?.toString(),
      );
}

class ListmentCourse {
  final String id;
  final String courseTitle;
  final String? courseDescription;
  final String? courseImageUrl;
  final String? courseIconUrl;
  final int? durationHours;
  final int? validityDays;
  final String? slug;
  final String? categoryName;
  final Map<String, dynamic>? stats;

  ListmentCourse({
    required this.id,
    required this.courseTitle,
    this.courseDescription,
    this.courseImageUrl,
    this.courseIconUrl,
    this.durationHours,
    this.validityDays,
    this.slug,
    this.categoryName,
    this.stats,
  });

  factory ListmentCourse.fromJson(Map<String, dynamic> json) =>
      ListmentCourse(
        id: json['id'] ?? '',
        courseTitle: json['courseTitle'] ?? '',
        courseDescription: json['courseDescription'],
        courseImageUrl: json['courseImageUrl'],
        courseIconUrl: json['courseIconUrl'],
        durationHours: json['durationHours'],
        validityDays: json['validityDays'],
        slug: json['slug']?.toString(),
        categoryName: json['categoryName']?.toString(),
        stats: json['stats'] as Map<String, dynamic>?,
      );
}

class ListmentModel {
  final String id;
  final String courseId;
  final String studentId;
  final String? ListmentDate;
  final String? expiryDate;
  final String? status;
  final ListmentProgress? progress;
  final ListmentCertificate? certificate;
  final ListmentCourse? course;
  final String? createdAt;
  final String? updatedAt;

  ListmentModel({
    required this.id,
    required this.courseId,
    required this.studentId,
    this.ListmentDate,
    this.expiryDate,
    this.status,
    this.progress,
    this.certificate,
    this.course,
    this.createdAt,
    this.updatedAt,
  });

  factory ListmentModel.fromJson(Map<String, dynamic> json) =>
      ListmentModel(
        id: json['id'] ?? '',
        courseId: json['courseId'] ?? '',
        studentId: json['studentId'] ?? '',
        ListmentDate: json['ListmentDate']?.toString(),
        expiryDate: json['expiryDate']?.toString(),
        status: json['status']?.toString(),
        progress: json['progress'] is Map<String, dynamic>
            ? ListmentProgress.fromJson(json['progress'])
            : null,
        certificate: json['certificate'] is Map<String, dynamic>
            ? ListmentCertificate.fromJson(json['certificate'])
            : null,
        course: json['course'] is Map<String, dynamic>
            ? ListmentCourse.fromJson(json['course'])
            : null,
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
      );
}
