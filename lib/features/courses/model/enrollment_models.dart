class EnrollmentProgress {
  final int completedLecturesCount;
  final int totalLectures;
  final double progressPercentage;
  final String? lastAccessedAt;
  final String? lastAccessedLectureId;

  EnrollmentProgress({
    required this.completedLecturesCount,
    required this.totalLectures,
    required this.progressPercentage,
    this.lastAccessedAt,
    this.lastAccessedLectureId,
  });

  factory EnrollmentProgress.fromJson(Map<String, dynamic> json) =>
      EnrollmentProgress(
        completedLecturesCount: json['completedLecturesCount'] ?? 0,
        totalLectures: json['totalLectures'] ?? 0,
        progressPercentage: (json['progressPercentage'] is num)
            ? (json['progressPercentage'] as num).toDouble()
            : 0.0,
        lastAccessedAt: json['lastAccessedAt']?.toString(),
        lastAccessedLectureId: json['lastAccessedLectureId']?.toString(),
      );
}

class EnrollmentCertificate {
  final bool issued;
  final String? issuedAt;
  final String? certificateUrl;
  final String? certificateNumber;

  EnrollmentCertificate({
    required this.issued,
    this.issuedAt,
    this.certificateUrl,
    this.certificateNumber,
  });

  factory EnrollmentCertificate.fromJson(Map<String, dynamic> json) =>
      EnrollmentCertificate(
        issued: json['issued'] ?? false,
        issuedAt: json['issuedAt']?.toString(),
        certificateUrl: json['certificateUrl']?.toString(),
        certificateNumber: json['certificateNumber']?.toString(),
      );
}

class EnrollmentCourse {
  final String id;
  final String courseTitle;
  final String? courseDescription;
  final String? courseImageUrl;
  final int? enrollmentCost;
  final int? durationHours;
  final int? validityDays;
  final String? slug;
  final String? categoryName;
  final Map<String, dynamic>? stats;

  EnrollmentCourse({
    required this.id,
    required this.courseTitle,
    this.courseDescription,
    this.courseImageUrl,
    this.enrollmentCost,
    this.durationHours,
    this.validityDays,
    this.slug,
    this.categoryName,
    this.stats,
  });

  factory EnrollmentCourse.fromJson(Map<String, dynamic> json) =>
      EnrollmentCourse(
        id: json['id'] ?? '',
        courseTitle: json['courseTitle'] ?? '',
        courseDescription: json['courseDescription'],
        courseImageUrl: json['courseImageUrl'],
        enrollmentCost: json['enrollmentCost'],
        durationHours: json['durationHours'],
        validityDays: json['validityDays'],
        slug: json['slug']?.toString(),
        categoryName: json['categoryName']?.toString(),
        stats: json['stats'] as Map<String, dynamic>?,
      );
}

class EnrollmentModel {
  final String id;
  final String courseId;
  final String studentId;
  final String? enrollmentDate;
  final String? expiryDate;
  final String? status;
  final String? paymentId;
  final EnrollmentProgress? progress;
  final EnrollmentCertificate? certificate;
  final EnrollmentCourse? course;
  final String? createdAt;
  final String? updatedAt;

  EnrollmentModel({
    required this.id,
    required this.courseId,
    required this.studentId,
    this.enrollmentDate,
    this.expiryDate,
    this.status,
    this.paymentId,
    this.progress,
    this.certificate,
    this.course,
    this.createdAt,
    this.updatedAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) =>
      EnrollmentModel(
        id: json['id'] ?? '',
        courseId: json['courseId'] ?? '',
        studentId: json['studentId'] ?? '',
        enrollmentDate: json['enrollmentDate']?.toString(),
        expiryDate: json['expiryDate']?.toString(),
        status: json['status']?.toString(),
        paymentId: json['paymentId']?.toString(),
        progress: json['progress'] is Map<String, dynamic>
            ? EnrollmentProgress.fromJson(json['progress'])
            : null,
        certificate: json['certificate'] is Map<String, dynamic>
            ? EnrollmentCertificate.fromJson(json['certificate'])
            : null,
        course: json['course'] is Map<String, dynamic>
            ? EnrollmentCourse.fromJson(json['course'])
            : null,
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
      );
}
