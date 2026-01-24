import 'course_models.dart';

class LiveClassModel {
  final String id;
  final String title;
  final String? description;
  final String? status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String? durationLabel;
  final String? courseId;
  final String? courseTitle;
  final String? subjectId;
  final String? subjectName;
  final String? lecturerId;
  final String? lecturerName;
  final String? lecturerImageUrl;
  final String? bannerImageUrl;
  final String? joinUrl;
  final Map<String, dynamic> raw;

  LiveClassModel({
    required this.id,
    required this.title,
    required this.raw,
    this.description,
    this.status,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.durationLabel,
    this.courseId,
    this.courseTitle,
    this.subjectId,
    this.subjectName,
    this.lecturerId,
    this.lecturerName,
    this.lecturerImageUrl,
    this.bannerImageUrl,
    this.joinUrl,
  });

  factory LiveClassModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is num) {
        // Assume seconds
        final millis = value.toInt();
        if (millis > 10000000000) {
          return DateTime.fromMillisecondsSinceEpoch(millis);
        }
        return DateTime.fromMillisecondsSinceEpoch(millis * 1000);
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    String? resolveBanner(Map<String, dynamic> source) {
      final banner = source['bannerImageUrl'] ??
          source['thumbnailUrl'] ??
          source['posterUrl'] ??
          source['imageUrl'];
      if (banner is String && banner.isNotEmpty) {
        return banner;
      }
      final course = source['course'];
      if (course is Map<String, dynamic>) {
        final courseBanner = course['courseImageUrl'] ?? course['bannerImage'];
        if (courseBanner is String && courseBanner.isNotEmpty) {
          return courseBanner;
        }
      }
      return null;
    }

    String? resolveJoinUrl(Map<String, dynamic> source) {
      final meeting = source['meeting'] ?? source['session'];
      if (meeting is Map<String, dynamic>) {
        final direct = meeting['joinUrl'] ?? meeting['meetingUrl'];
        if (direct is String && direct.isNotEmpty) return direct;
        final links = meeting['links'];
        if (links is Map<String, dynamic>) {
          final join = links['join'] ?? links['joinUrl'];
          if (join is String && join.isNotEmpty) return join;
        }
      }
      final direct = source['joinUrl'] ?? source['meetingUrl'] ?? source['url'];
      if (direct is String && direct.isNotEmpty) return direct;
      return null;
    }

    final course = map['course'] is Map
        ? Map<String, dynamic>.from(map['course'] as Map)
        : null;
    final subject = map['subject'] is Map
        ? Map<String, dynamic>.from(map['subject'] as Map)
        : null;
    final lecturer = map['lecturer'] is Map
        ? Map<String, dynamic>.from(map['lecturer'] as Map)
        : null;

    final title = map['title']?.toString() ??
        map['name']?.toString() ??
        course?['courseTitle']?.toString() ??
        'Live Class';

    return LiveClassModel(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      title: title,
      description: map['description']?.toString(),
      status: map['status']?.toString(),
      startTime: parseDate(
        map['startTime'] ?? map['startsAt'] ?? map['scheduledAt'],
      ),
      endTime: parseDate(map['endTime'] ?? map['endsAt']),
      durationMinutes: parseInt(
        map['durationMinutes'] ?? map['duration'] ?? map['durationInMinutes'],
      ),
      durationLabel:
          map['durationLabel']?.toString() ?? map['durationText']?.toString(),
      courseId: map['courseId']?.toString() ?? course?['id']?.toString(),
      courseTitle:
          course?['courseTitle']?.toString() ?? map['courseTitle']?.toString(),
      subjectId: map['subjectId']?.toString() ?? subject?['id']?.toString(),
      subjectName:
          subject?['subjectName']?.toString() ?? map['subjectName']?.toString(),
      lecturerId: map['lecturerId']?.toString() ?? lecturer?['id']?.toString(),
      lecturerName:
          lecturer?['fullName']?.toString() ?? map['lecturerName']?.toString(),
      lecturerImageUrl: lecturer?['profilePictureUrl']?.toString() ??
          lecturer?['profileImageUrl']?.toString(),
      bannerImageUrl: resolveBanner(map),
      joinUrl: resolveJoinUrl(map),
      raw: map,
    );
  }

  /// Calculate actual status based on current time
  /// DO NOT rely on backend 'status' field - it's often stale
  /// Returns: 'upcoming', 'ongoing', or 'ended'
  String calculateActualStatus() {
    // If no start time, fall back to backend status
    if (startTime == null) {
      return status?.toLowerCase() ?? 'upcoming';
    }

    final now = DateTime.now().toUtc();
    final start = startTime!.toUtc();
    
    // Calculate end time
    DateTime end;
    if (endTime != null) {
      end = endTime!.toUtc();
    } else if (durationMinutes != null) {
      end = start.add(Duration(minutes: durationMinutes!));
    } else {
      // No duration info, assume 60 minutes default
      end = start.add(const Duration(minutes: 60));
    }

    // Time-based status calculation
    if (now.isBefore(start)) {
      return 'upcoming';
    } else if (now.isAfter(end)) {
      return 'ended';
    } else {
      return 'ongoing';
    }
  }

  /// Check if class is currently joinable
  bool get isJoinable => calculateActualStatus() == 'ongoing';

  /// Check if class is upcoming
  bool get isUpcoming => calculateActualStatus() == 'upcoming';

  /// Check if class has ended
  bool get hasEnded => calculateActualStatus() == 'ended';
}

class PagedLiveClasses {
  final List<LiveClassModel> data;
  final PagedMeta? meta;

  const PagedLiveClasses({
    required this.data,
    required this.meta,
  });

  factory PagedLiveClasses.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final list = (json['data'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(LiveClassModel.fromJson)
              .toList(growable: false) ??
          const <LiveClassModel>[];
      final meta = json['meta'] is Map<String, dynamic>
          ? PagedMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null;
      return PagedLiveClasses(data: list, meta: meta);
    }
    if (json is List) {
      final list = json
          .whereType<Map<String, dynamic>>()
          .map(LiveClassModel.fromJson)
          .toList(growable: false);
      return PagedLiveClasses(data: list, meta: null);
    }
    return const PagedLiveClasses(data: <LiveClassModel>[], meta: null);
  }
}

/// Response from POST /live-classes/{id}/join-token
/// Contains Zoom SDK JWT token and meeting metadata
class LiveClassJoinToken {
  final String token; // Zoom SDK JWT token
  final String sessionName; // Meeting display name
  final String userName; // User's display name in meeting
  final String? meetingId; // Optional Zoom meeting ID
  final String? password; // Optional meeting password

  const LiveClassJoinToken({
    required this.token,
    required this.sessionName,
    required this.userName,
    this.meetingId,
    this.password,
  });

  factory LiveClassJoinToken.fromJson(Map<String, dynamic> json) {
    return LiveClassJoinToken(
      token: json['token']?.toString() ?? '',
      sessionName: json['sessionName']?.toString() ?? 'Live Class',
      userName: json['userName']?.toString() ?? 'Student',
      meetingId: json['meetingId']?.toString(),
      password: json['password']?.toString(),
    );
  }
}
