class MockTestListResponse {
  const MockTestListResponse({
    required this.tests,
    this.meta,
  });

  final List<MockTest> tests;
  final MockTestMeta? meta;

  factory MockTestListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final metaJson = json['meta'];
    return MockTestListResponse(
      tests: _parseTestList(data),
      meta: metaJson is Map<String, dynamic>
          ? MockTestMeta.fromJson(metaJson)
          : metaJson is Map
              ? MockTestMeta.fromJson(Map<String, dynamic>.from(metaJson))
              : null,
    );
  }
}

class MockTestMeta {
  const MockTestMeta({
    this.page,
    this.limit,
    this.total,
    this.totalPages,
    this.hasNext,
    this.hasPrevious,
  });

  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;
  final bool? hasNext;
  final bool? hasPrevious;

  factory MockTestMeta.fromJson(Map<String, dynamic> json) {
    return MockTestMeta(
      page: _asInt(json['page'] ?? json['currentPage'] ?? json['pageNumber']),
      limit: _asInt(json['limit'] ?? json['perPage'] ?? json['pageSize']),
      total: _asInt(json['total'] ?? json['totalItems']),
      totalPages:
          _asInt(json['totalPages'] ?? json['totalPage'] ?? json['pages']),
      hasNext: _asBool(json['hasNext'] ?? json['hasNextPage']),
      hasPrevious: _asBool(json['hasPrevious'] ?? json['hasPreviousPage']),
    );
  }
}

class MockTest {
  const MockTest({
    required this.id,
    required this.courseId,
    this.title,
    this.description,
    this.instructions = const <String>[],
    this.testType,
    this.subjectId,
    this.subjectName,
    this.subjectDistribution = const <Map<String, dynamic>>[],
    this.numberOfQuestions,
    this.cost,
    this.durationMinutes,
    this.passingPercentage,
    this.attemptsAllowed,
    this.totalAttempts,
    this.averageScore,
    this.attemptsUsed,
    this.remainingAttempts,
    this.maxAttemptsReached,
    this.isFree = false,
    this.isPurchased = false,
    this.canTakeTest = false,
    this.extra,
  });

  final String id;
  final String courseId;
  final String? title;
  final String? description;
  final List<String> instructions;
  final String? testType;
  final String? subjectId;
  final String? subjectName;
  final List<Map<String, dynamic>> subjectDistribution;
  final int? numberOfQuestions;
  final double? cost;
  final int? durationMinutes;
  final double? passingPercentage;
  final int? attemptsAllowed;
  final int? totalAttempts;
  final double? averageScore;
  final int? attemptsUsed;
  final int? remainingAttempts;
  final bool? maxAttemptsReached;
  final bool isFree;
  final bool isPurchased;
  final bool canTakeTest;
  final Map<String, dynamic>? extra;

  factory MockTest.fromJson(Map<String, dynamic> json) {
    final subjectDistribution =
        _asList(json['subjectDistribution']).map<Map<String, dynamic>>((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }
      return <String, dynamic>{'value': item};
    }).toList();

    return MockTest(
      id: _asString(json['id'] ?? json['mockTestId'] ?? json['testId']) ?? '',
      courseId: _parseCourseId(json),
      title: _asString(json['title'] ?? json['name']),
      description: _asString(json['description']),
      instructions: _parseInstructions(json['instructions']),
      testType: _asString(json['testType']),
      subjectId: _asString(json['subjectId']),
      subjectName: _asString(json['subjectName']),
      subjectDistribution: subjectDistribution,
      numberOfQuestions:
          _asInt(json['numberOfQuestions'] ?? json['questionCount']),
      cost: _asDouble(json['cost'] ?? json['price']),
      durationMinutes:
          _asInt(json['durationMinutes'] ?? json['duration'] ?? json['time']),
      passingPercentage:
          _asDouble(json['passingPercentage'] ?? json['passPercentage']),
      attemptsAllowed: _asInt(json['attemptsAllowed'] ?? json['maxAttempts']),
      totalAttempts: _asInt(json['totalAttempts']),
      averageScore:
          _asDouble(json['averageScore'] ?? json['avgScore'] ?? json['score']),
      attemptsUsed: _asInt(json['attemptsUsed'] ?? json['attemptCount']),
      remainingAttempts:
          _asInt(json['remainingAttempts'] ?? json['attemptsRemaining']),
      maxAttemptsReached:
          _asBool(json['maxAttemptsReached'] ?? json['isLockedOut']),
      isFree: _asBool(json['isFree'] ?? json['free']) ??
          (_asDouble(json['cost'] ?? json['price']) ?? 0) == 0,
      isPurchased: _asBool(json['isPurchased'] ?? json['purchased']) ?? false,
      canTakeTest:
          _asBool(json['canTakeTest'] ?? json['canStart'] ?? json['allowed']) ??
              false,
      extra: json['extra'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['extra'] as Map<String, dynamic>)
          : json['extra'] is Map
              ? Map<String, dynamic>.from(json['extra'] as Map)
              : null,
    );
  }

  MockTest copyWith({
    String? courseId,
    bool? isPurchased,
    bool? canTakeTest,
  }) {
    return MockTest(
      id: id,
      courseId: courseId ?? this.courseId,
      title: title,
      description: description,
      instructions: instructions,
      testType: testType,
      subjectId: subjectId,
      subjectName: subjectName,
      subjectDistribution: subjectDistribution,
      numberOfQuestions: numberOfQuestions,
      cost: cost,
      durationMinutes: durationMinutes,
      passingPercentage: passingPercentage,
      attemptsAllowed: attemptsAllowed,
      totalAttempts: totalAttempts,
      averageScore: averageScore,
      attemptsUsed: attemptsUsed,
      remainingAttempts: remainingAttempts,
      maxAttemptsReached: maxAttemptsReached,
      isFree: this.isFree,
      isPurchased: isPurchased ?? this.isPurchased,
      canTakeTest: canTakeTest ?? this.canTakeTest,
      extra: extra,
    );
  }
}

String _parseCourseId(Map<String, dynamic> json) {
  final directId = _asString(json['courseId'] ?? json['course_id']);
  if (directId != null && directId.isNotEmpty) {
    return directId;
  }
  final course = json['course'];
  if (course is Map<String, dynamic>) {
    final id = _asString(course['id']);
    if (id != null && id.isNotEmpty) {
      return id;
    }
  } else if (course is Map) {
    final courseMap = Map<String, dynamic>.from(course);
    final id = _asString(courseMap['id']);
    if (id != null && id.isNotEmpty) {
      return id;
    }
  }
  return '';
}

List<MockTest> _parseTestList(dynamic data) {
  if (data is List) {
    return data
        .map((item) => item is Map<String, dynamic>
            ? MockTest.fromJson(item)
            : item is Map
                ? MockTest.fromJson(Map<String, dynamic>.from(item))
                : null)
        .whereType<MockTest>()
        .toList();
  }
  if (data is Map<String, dynamic>) {
    return [MockTest.fromJson(data)];
  }
  if (data is Map) {
    return [MockTest.fromJson(Map<String, dynamic>.from(data))];
  }
  return const <MockTest>[];
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  if (value == null) return const <dynamic>[];
  return <dynamic>[value];
}

List<String> _parseInstructions(dynamic value) {
  if (value == null) return const <String>[];
  if (value is List) {
    return value
        .map((item) => _asString(item))
        .where((item) => item?.isNotEmpty == true)
        .map((item) => item!)
        .toList();
  }
  final text = _asString(value);
  if (text != null && text.isNotEmpty) {
    return text
        .split(RegExp(r'\r?\n'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
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

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
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
