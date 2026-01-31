class ExamListResponse {
  const ExamListResponse({
    required this.items,
    this.meta,
  });

  final List<ExamListItem> items;
  final ExamListMeta? meta;

  factory ExamListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final metaJson = json['meta'];
    return ExamListResponse(
      items: _decodeList(data, ExamListItem.fromJson),
      meta: metaJson is Map<String, dynamic>
          ? ExamListMeta.fromJson(metaJson)
          : metaJson is Map
              ? ExamListMeta.fromJson(Map<String, dynamic>.from(metaJson))
              : null,
    );
  }
}

class ExamListItem {
  const ExamListItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.thumbnailUrl,
    this.status,
    this.categoryId,
    this.categoryName,
    this.totalQuestions,
    this.durationMinutes,
    this.price,
    this.isFree,
    this.isPurchased,
    this.validFrom,
    this.validTo,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? thumbnailUrl;
  final String? status;
  final String? categoryId;
  final String? categoryName;
  final int? totalQuestions;
  final int? durationMinutes;
  final double? price;
  final bool? isFree;
  final bool? isPurchased;
  final DateTime? validFrom;
  final DateTime? validTo;

  factory ExamListItem.fromJson(Map<String, dynamic> json) {
    final root = Map<String, dynamic>.from(json);
    final nested = root['exam'] is Map
        ? Map<String, dynamic>.from(root['exam'] as Map)
        : null;
    final source = nested ?? root;
    final price = _double(source['price'] ?? source['enrollmentCost']);
    final isFree = source['isFree'];

    return ExamListItem(
      id: _string(source['id'] ?? source['_id'] ?? source['examId']) ?? '',
      title: _string(
            source['title'] ??
                source['name'] ??
                source['examTitle'] ??
                source['exam_name'],
          ) ??
          '',
      subtitle: _string(source['description'] ?? source['subtitle']),
      thumbnailUrl: _string(
        source['thumbnailUrl'] ??
            source['image'] ??
            source['cover'] ??
            source['imageUrl'] ??
            source['examImageUrl'],
      ),
      status: _string(source['status']),
      categoryId: _string(
        source['categoryId'] ?? source['category_id'] ?? source['category'],
      ),
      categoryName: _string(
        source['categoryName'] ??
            source['category_name'] ??
            (source['category'] is Map
                ? (source['category'] as Map)['name']
                : null),
      ),
      totalQuestions: _int(
        source['totalQuestions'] ??
            source['questionCount'] ??
            source['total_questions'],
      ),
      durationMinutes: _int(
        source['durationMinutes'] ??
            source['examDuration'] ??
            source['duration'] ??
            source['duration_minutes'],
      ),
      price: price,
      isFree: isFree is bool
          ? isFree
          : isFree is num
              ? isFree == 1
              : _string(isFree)?.toLowerCase() == 'true',
      isPurchased: _toBool(source['isPurchased'] ?? source['purchased']),
      validFrom: _dateOrNull(source['validFrom'] ?? source['valid_from']),
      validTo: _dateOrNull(source['validTo'] ?? source['valid_to']),
    );
  }
}

class ExamListMeta {
  const ExamListMeta({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
  });

  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;
  final int? from;
  final int? to;

  bool get hasNextPage =>
      lastPage != null && currentPage != null && currentPage! < lastPage!;
  bool get hasPreviousPage => currentPage != null && currentPage! > 1;

  factory ExamListMeta.fromJson(Map<String, dynamic> json) {
    return ExamListMeta(
      currentPage: _int(json['currentPage'] ?? json['current_page']),
      lastPage: _int(json['lastPage'] ?? json['last_page']),
      perPage: _int(json['perPage'] ?? json['per_page']),
      total: _int(json['total']),
      from: _int(json['from']),
      to: _int(json['to']),
    );
  }
}

class ExamDetail {
  const ExamDetail({
    required this.id,
    required this.title,
    this.description,
    this.totalQuestions,
    this.durationMinutes,
    this.timePerQuestionSeconds,
    this.passingScore,
    this.isFree,
    this.isPurchased,
    this.price,
    this.thumbnailUrl,
    this.validFrom,
    this.validTo,
    this.instructions = const <String>[],
    this.courses = const <ExamCourseDetail>[],
    this.metadata,
  });

  final String id;
  final String title;
  final String? description;
  final int? totalQuestions;
  final int? durationMinutes;
  final int? timePerQuestionSeconds;
  final double? passingScore;
  final bool? isFree;
  final bool? isPurchased;
  final double? price;
  final String? thumbnailUrl;
  final DateTime? validFrom;
  final DateTime? validTo;
  final List<String> instructions;
  final List<ExamCourseDetail> courses;
  final Map<String, dynamic>? metadata;

  factory ExamDetail.fromJson(Map<String, dynamic> json) {
    final price = _double(json['price'] ?? json['enrollmentCost']);
    return ExamDetail(
      id: _string(json['id'] ?? json['_id'] ?? json['examId']) ?? '',
      title: _string(json['title'] ?? json['name'] ?? json['examTitle']) ?? '',
      description: _string(json['description'] ?? json['summary']),
      totalQuestions: _int(
        json['totalQuestions'] ??
            json['questionCount'] ??
            json['question_count'],
      ),
      durationMinutes: _int(
        json['durationMinutes'] ??
            json['duration'] ??
            json['duration_minutes'] ??
            json['examDuration'],
      ),
      timePerQuestionSeconds: _int(json['timePerQuestionSeconds']),
      passingScore: _double(json['passingScore'] ?? json['passScore']),
      isFree: _toBool(json['isFree'] ?? json['free']),
      isPurchased: _toBool(json['isPurchased'] ?? json['purchased']),
      price: price,
      thumbnailUrl: _string(
        json['thumbnailUrl'] ??
            json['image'] ??
            json['cover'] ??
            json['imageUrl'] ??
            json['examImageUrl'],
      ),
      validFrom: _dateOrNull(json['validFrom'] ?? json['valid_from']),
      validTo: _dateOrNull(json['validTo'] ?? json['valid_to']),
      instructions: _decodeStringList(json['instructions']),
      courses: _decodeList(json['courses'], ExamCourseDetail.fromJson),
      metadata: json['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['meta'] as Map<String, dynamic>)
          : json['meta'] is Map
              ? Map<String, dynamic>.from(json['meta'] as Map)
              : null,
    );
  }
}

class ExamCourseDetail {
  const ExamCourseDetail({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.enrollmentCost,
    this.durationHours,
    this.validityDays,
    this.isSaved,
  });

  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final double? enrollmentCost;
  final int? durationHours;
  final int? validityDays;
  final bool? isSaved;

  factory ExamCourseDetail.fromJson(Map<String, dynamic> json) {
    return ExamCourseDetail(
      id: _string(json['id'] ?? json['_id'] ?? json['courseId']) ?? '',
      title:
          _string(json['title'] ?? json['courseTitle'] ?? json['name']) ?? '',
      description: _string(
        json['description'] ?? json['courseDescription'],
      ),
      thumbnailUrl: _string(
        json['courseIconUrl'] ??
            json['image'] ??
            json['courseImageUrl'] ??
            json['cover'],
      ),
      enrollmentCost: _double(json['enrollmentCost'] ?? json['price']),
      durationHours: _int(json['durationHours'] ?? json['duration_hours']),
      validityDays: _int(json['validityDays'] ?? json['validity_days']),
      isSaved: _toBool(json['isSaved'] ?? json['saved']),
    );
  }
}

List<T> _decodeList<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) factoryFn,
) {
  if (data is List) {
    return data
        .map((raw) {
          if (raw is Map<String, dynamic>) {
            return raw;
          }
          if (raw is Map) {
            return Map<String, dynamic>.from(raw);
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .map(factoryFn)
        .toList();
  }

  if (data is Map<String, dynamic>) {
    return [factoryFn(data)];
  }

  if (data is Map) {
    return [factoryFn(Map<String, dynamic>.from(data))];
  }

  return <T>[];
}

List<String> _decodeStringList(dynamic value) {
  if (value == null) return const <String>[];
  if (value is List) {
    return value
        .map((item) => item is String
            ? item
            : item is Map && item['text'] != null
                ? item['text'].toString()
                : item?.toString() ?? '')
        .where((element) => element.isNotEmpty)
        .toList();
  }
  if (value is String) {
    return value
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();
  }
  return const <String>[];
}

String? _string(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

int? _int(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _double(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == 'yes' || text == '1') return true;
  if (text == 'false' || text == 'no' || text == '0') return false;
  return null;
}

DateTime? _dateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return DateTime.tryParse(value.toString());
}
