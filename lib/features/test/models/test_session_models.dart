class TestSession {
  const TestSession({
    required this.sessionId,
    required this.mockTestId,
    this.examId,
    this.examTitle,
    this.status,
    this.currentQuestionIndex,
    this.totalQuestions,
    this.durationMinutes,
    this.startedAt,
    this.endsAt,
    this.questions = const <TestQuestion>[],
    this.answers = const <int, AnswerState>{},
  });

  final String sessionId;
  final String mockTestId;
  final String? examId;
  final String? examTitle;
  final String? status;
  final int? currentQuestionIndex;
  final int? totalQuestions;
  final int? durationMinutes;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final List<TestQuestion> questions;
  final Map<int, AnswerState> answers;

  factory TestSession.fromJson(Map<String, dynamic> json) {
    return TestSession(
      sessionId: _string(json['id'] ?? json['sessionId'] ?? json['_id']) ?? '',
      mockTestId: _string(json['mockTestId'] ?? json['mock_test_id']) ?? '',
      examId: _string(json['examId'] ?? json['exam_id']),
      examTitle:
          _string(json['examTitle'] ?? json['title'] ?? json['exam_name']),
      status: _string(json['status']),
      currentQuestionIndex: _int(json['currentQuestionIndex'] ?? json['index']),
      totalQuestions: _int(
          json['totalQuestions'] ?? json['questionCount'] ?? json['total']),
      durationMinutes: _int(
          json['durationMinutes'] ?? json['duration'] ?? json['timeLimit']),
      startedAt: _dateOrNull(json['startedAt'] ?? json['started_at']),
      endsAt:
          _dateOrNull(json['endsAt'] ?? json['expiresAt'] ?? json['ends_at']),
      questions: _decodeList(json['questions'], TestQuestion.fromJson),
      answers: _decodeAnswers(json['answers']),
    );
  }

  TestSession copyWith({
    int? currentQuestionIndex,
    Map<int, AnswerState>? answers,
    List<TestQuestion>? questions,
    String? status,
  }) {
    return TestSession(
      sessionId: sessionId,
      mockTestId: mockTestId,
      examId: examId,
      examTitle: examTitle,
      status: status ?? this.status,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      totalQuestions: totalQuestions,
      durationMinutes: durationMinutes,
      startedAt: startedAt,
      endsAt: endsAt,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
    );
  }

  // Determines if the session has expired based on endsAt
  bool get isExpired => endsAt?.isBefore(DateTime.now()) ?? false;

}

class TestQuestion {
  const TestQuestion({
    required this.index,
    required this.questionId,
    required this.prompt,
    this.description,
    this.imageUrl,
    this.explanation,
    this.options = const <TestQuestionOption>[],
    this.selectedOptionKey,
    this.isMarkedForReview,
  });

  final int index;
  final String questionId;
  final String prompt;
  final String? description;
  final String? imageUrl;
  final String? explanation;
  final List<TestQuestionOption> options;
  final String? selectedOptionKey;
  final bool? isMarkedForReview;

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    var options = _decodeList(json['options'], TestQuestionOption.fromJson)
        .where((option) => option.key.isNotEmpty || option.label.isNotEmpty)
        .toList();
    if (options.isEmpty) {
      options = _buildFallbackOptions(json);
    }
    final selected = json['selectedOption'] ?? json['selectedAnswer'];
    return TestQuestion(
      index: _int(json['index'] ?? json['questionIndex']) ?? 0,
      questionId:
          _string(json['id'] ?? json['questionId'] ?? json['_id']) ?? '',
      prompt: _string(json['prompt'] ??
              json['questionText'] ??
              json['question'] ??
              json['text']) ??
          '',
      description: _string(json['description'] ?? json['subtext']),
      imageUrl: _string(json['imageUrl'] ?? json['image']),
      explanation: _string(json['explanation'] ?? json['solution']),
      options: options,
      selectedOptionKey: _string(selected),
      isMarkedForReview: _toBool(json['isMarkedForReview'] ?? json['flagged']),
    );
  }

  TestQuestion copyWith({
    String? selectedOptionKey,
    bool? isMarkedForReview,
    List<TestQuestionOption>? options,
  }) {
    return TestQuestion(
      index: index,
      questionId: questionId,
      prompt: prompt,
      description: description,
      imageUrl: imageUrl,
      explanation: explanation,
      options: options ?? this.options,
      selectedOptionKey: selectedOptionKey ?? this.selectedOptionKey,
      isMarkedForReview: isMarkedForReview ?? this.isMarkedForReview,
    );
  }
}

class TestQuestionOption {
  const TestQuestionOption({
    required this.key,
    required this.label,
    this.isCorrect,
  });

  final String key;
  final String label;
  final bool? isCorrect;

  factory TestQuestionOption.fromJson(Map<String, dynamic> json) {
    final key = json['key'] ?? json['option'] ?? json['value'];
    final label = json['label'] ?? json['text'] ?? json['answer'];
    return TestQuestionOption(
      key: _string(key) ?? '',
      label: _string(label) ?? '',
      isCorrect: _toBool(json['isCorrect'] ?? json['correct']),
    );
  }
}

class AnswerState {
  const AnswerState({
    required this.selectedOptionKey,
    this.submittedAt,
    this.isMarkedForReview,
    this.isCorrect,
  });

  final String selectedOptionKey;
  final DateTime? submittedAt;
  final bool? isMarkedForReview;
  final bool? isCorrect;

  factory AnswerState.fromJson(Map<String, dynamic> json) {
    return AnswerState(
      selectedOptionKey:
          _string(json['selectedOption'] ?? json['selectedAnswer']) ?? '',
      submittedAt: _dateOrNull(json['submittedAt'] ?? json['submitted_at']),
      isMarkedForReview: _toBool(json['isMarkedForReview'] ?? json['flagged']),
      isCorrect: _toBool(json['isCorrect'] ?? json['correct']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedOption': selectedOptionKey,
      if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
      if (isMarkedForReview != null) 'isMarkedForReview': isMarkedForReview,
      if (isCorrect != null) 'isCorrect': isCorrect,
    };
  }
}

class AnswerSubmitRequest {
  const AnswerSubmitRequest({
    required this.questionIndex,
    required this.selectedAnswer,
  });

  final int questionIndex;
  final String selectedAnswer;

  Map<String, dynamic> toJson() {
    return {
      'questionIndex': questionIndex,
      'selectedAnswer': selectedAnswer,
    };
  }
}

class MarkReviewRequest {
  const MarkReviewRequest({
    required this.questionIndex,
    required this.markForReview,
  });

  final int questionIndex;
  final bool markForReview;

  Map<String, dynamic> toJson() {
    return {
      'questionIndex': questionIndex,
      'markForReview': markForReview,
    };
  }
}

class NavigateRequest {
  const NavigateRequest({
    required this.questionIndex,
  });

  final int questionIndex;

  Map<String, dynamic> toJson() {
    return {
      'questionIndex': questionIndex,
    };
  }
}

class TestSummary {
  const TestSummary({
    this.totalQuestions,
    this.attempted,
    this.correct,
    this.incorrect,
    this.skipped,
    this.markedForReview,
    this.score,
    this.percentage,
    this.timeSpentSeconds,
  });

  final int? totalQuestions;
  final int? attempted;
  final int? correct;
  final int? incorrect;
  final int? skipped;
  final int? markedForReview;
  final double? score;
  final double? percentage;
  final int? timeSpentSeconds;

  factory TestSummary.fromJson(Map<String, dynamic> json) {
    final total = _int(json['totalQuestions'] ??
        json['total_questions'] ??
        json['total'] ??
        json['questionCount']);
    final skipped = _int(json['skippedQuestions'] ??
        json['skipped_questions'] ??
        json['skipped'] ??
        json['unattempted']);
    var attempted = _int(json['attempted'] ??
        json['attemptedQuestions'] ??
        json['attempted_questions'] ??
        json['attemptedCount']);
    if (attempted == null && total != null && skipped != null) {
      final computed = total - skipped;
      attempted = computed < 0 ? 0 : computed;
    }
    final correct = _int(json['correctAnswers'] ??
        json['correct_answers'] ??
        json['correct'] ??
        json['rightAnswers']);
    var incorrect = _int(json['wrongAnswers'] ??
        json['wrong_answers'] ??
        json['incorrect'] ??
        json['incorrectAnswers'] ??
        json['wrong']);
    if (incorrect == null && attempted != null && correct != null) {
      final computed = attempted - correct;
      incorrect = computed < 0 ? 0 : computed;
    }
    return TestSummary(
      totalQuestions: total,
      attempted: attempted,
      correct: correct,
      incorrect: incorrect,
      skipped: skipped,
      markedForReview: _int(json['markedForReview'] ?? json['flagged']),
      score: _double(json['score'] ?? json['overallScore']),
      percentage: _double(json['scorePercentage'] ??
          json['score_percentage'] ??
          json['percentage'] ??
          json['accuracy']),
      timeSpentSeconds: _int(json['timeSpentSeconds'] ??
          json['time_spent_seconds'] ??
          json['timeSpent']),
    );
  }
}

class TestResult {
  const TestResult({
    this.summary,
    this.rank,
    this.percentile,
    this.feedback,
    this.completedAt,
    this.totalQuestions,
    this.correctAnswers,
    this.wrongAnswers,
    this.skippedQuestions,
    this.scorePercentage,
    this.passed,
  });

  final TestSummary? summary;
  final int? rank;
  final double? percentile;
  final String? feedback;
  final DateTime? completedAt;
  final int? totalQuestions;
  final int? correctAnswers;
  final int? wrongAnswers;
  final int? skippedQuestions;
  final double? scorePercentage;
  final bool? passed;

  factory TestResult.fromJson(Map<String, dynamic> json) {
    final summaryPayload = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : null;
    final derivedSummary = summaryPayload != null
        ? TestSummary.fromJson(summaryPayload)
        : TestSummary.fromJson(json);
    final total = _int(json['totalQuestions'] ?? json['total_questions']) ??
        derivedSummary.totalQuestions;
    final correct = _int(json['correctAnswers'] ??
            json['correct_answers'] ??
            json['correct']) ??
        derivedSummary.correct;
    final wrong = _int(json['wrongAnswers'] ??
            json['wrong_answers'] ??
            json['incorrect'] ??
            json['incorrectAnswers']) ??
        derivedSummary.incorrect;
    final skipped = _int(json['skippedQuestions'] ??
            json['skipped_questions'] ??
            json['skipped']) ??
        derivedSummary.skipped;
    final percentage = _double(json['scorePercentage'] ??
            json['score_percentage'] ??
            json['percentage']) ??
        derivedSummary.percentage;
    return TestResult(
      summary: derivedSummary,
      rank: _int(json['rank']),
      percentile: _double(json['percentile']),
      feedback: _string(json['feedback'] ?? json['remarks']),
      completedAt: _dateOrNull(json['completedAt'] ?? json['completed_at']),
      totalQuestions: total,
      correctAnswers: correct,
      wrongAnswers: wrong,
      skippedQuestions: skipped,
      scorePercentage: percentage,
      passed: _toBool(json['passed'] ?? json['isPassed'] ?? json['hasPassed']),
    );
  }
}

class TestSolution {
  const TestSolution({
    this.question,
    this.questionText,
    this.options = const <String, String>{},
    this.selectedAnswerKey,
    this.correctOptionKey,
    this.correctAnswerText,
    this.isCorrect,
    this.explanation,
    this.media,
  });

  final TestQuestion? question;
  final String? questionText;
  final Map<String, String> options;
  final String? selectedAnswerKey;
  final String? correctOptionKey;
  final String? correctAnswerText;
  final bool? isCorrect;
  final String? explanation;
  final List<String>? media;

  factory TestSolution.fromJson(Map<String, dynamic> json) {
    final questionPayload = json['question'];
    TestQuestion? resolvedQuestion;
    List<TestQuestionOption> questionOptions = const <TestQuestionOption>[];
    if (questionPayload is Map<String, dynamic>) {
      resolvedQuestion = TestQuestion.fromJson(questionPayload);
      questionOptions = resolvedQuestion.options;
    } else if (questionPayload is Map) {
      resolvedQuestion =
          TestQuestion.fromJson(Map<String, dynamic>.from(questionPayload));
      questionOptions = resolvedQuestion.options;
    }

    final prompt = _string(json['questionText'] ?? json['prompt']) ??
        resolvedQuestion?.prompt;

    final Map<String, String> optionMap = <String, String>{};
    void addOption(String key, dynamic value) {
      final candidate = _string(value);
      if (candidate != null && candidate.trim().isNotEmpty) {
        optionMap[key] = candidate.trim();
      }
    }

    for (final key in [
      'option1',
      'option2',
      'option3',
      'option4',
      'option5',
      'option6'
    ]) {
      addOption(key, json[key]);
      if (questionPayload is Map) {
        addOption(key, questionPayload[key]);
      }
    }

    if (optionMap.isEmpty && questionOptions.isNotEmpty) {
      for (var i = 0; i < questionOptions.length; i++) {
        final option = questionOptions[i];
        final key = option.key.isNotEmpty ? option.key : 'option${i + 1}';
        if (!optionMap.containsKey(key) && option.label.isNotEmpty) {
          optionMap[key] = option.label;
        }
      }
    }

    final selectedKey = _string(json['selectedAnswer'] ??
            json['selectedOption'] ??
            json['selected']) ??
        resolvedQuestion?.selectedOptionKey;

    String? correctKey =
        _string(json['correctOption'] ?? json['correctOptionKey']);
    String? correctAnswerText = _string(json['correctAnswer']);
    bool? isCorrect = _toBool(json['isCorrect']);

    TestQuestionOption? correctOptionFromQuestion;
    for (final option in questionOptions) {
      if (option.isCorrect == true) {
        correctOptionFromQuestion = option;
        break;
      }
    }

    if (correctKey == null || correctKey.isEmpty) {
      if (correctOptionFromQuestion != null &&
          correctOptionFromQuestion.key.isNotEmpty) {
        correctKey = correctOptionFromQuestion.key;
      } else if (correctAnswerText != null && correctAnswerText.isNotEmpty) {
        final detected = optionMap.entries.firstWhere(
          (entry) =>
              entry.value.trim().toLowerCase() ==
              correctAnswerText!.trim().toLowerCase(),
          orElse: () => const MapEntry<String, String>('', ''),
        );
        if (detected.key.isNotEmpty) {
          correctKey = detected.key;
        }
      }
    }

    if ((correctAnswerText == null || correctAnswerText.isEmpty) &&
        correctKey != null) {
      final entry = optionMap.entries.firstWhere(
        (element) => element.key.toLowerCase() == correctKey!.toLowerCase(),
        orElse: () => optionMap.entries.isEmpty
            ? const MapEntry<String, String>('', '')
            : optionMap.entries.first,
      );
      if (entry.key.isNotEmpty) {
        correctAnswerText = entry.value;
      }
    }

    if ((correctAnswerText == null || correctAnswerText.isEmpty) &&
        correctOptionFromQuestion != null &&
        correctOptionFromQuestion.label.isNotEmpty) {
      correctAnswerText = correctOptionFromQuestion.label;
    }

    if (isCorrect == null && selectedKey != null && correctAnswerText != null) {
      String? selectedText = optionMap[selectedKey];
      if ((selectedText == null || selectedText.isEmpty) &&
          questionOptions.isNotEmpty) {
        for (final option in questionOptions) {
          if (option.key == selectedKey) {
            selectedText = option.label;
            break;
          }
        }
      }
      if (selectedText != null && selectedText.isNotEmpty) {
        isCorrect = selectedText.trim().toLowerCase() ==
            correctAnswerText.trim().toLowerCase();
      }
    }

    return TestSolution(
      question: resolvedQuestion,
      questionText: prompt,
      options: Map.unmodifiable(optionMap),
      selectedAnswerKey: selectedKey,
      correctOptionKey: correctKey,
      correctAnswerText: correctAnswerText,
      isCorrect: isCorrect,
      explanation: _string(json['explanation'] ?? json['solution']),
      media: _decodeStringList(json['media'] ?? json['attachments']),
    );
  }
}

class TestHistoryItem {
  const TestHistoryItem({
    required this.sessionId,
    this.mockTestId,
    this.examTitle,
    this.score,
    this.percentage,
    this.correct,
    this.incorrect,
    this.attempted,
    this.totalQuestions,
    this.completedAt,
    this.durationMinutes,
  });

  final String sessionId;
  final String? mockTestId;
  final String? examTitle;
  final double? score;
  final double? percentage;
  final int? correct;
  final int? incorrect;
  final int? attempted;
  final int? totalQuestions;
  final DateTime? completedAt;
  final int? durationMinutes;

  factory TestHistoryItem.fromJson(Map<String, dynamic> json) {
    return TestHistoryItem(
      sessionId: _string(json['sessionId'] ?? json['id'] ?? json['_id']) ?? '',
      mockTestId: _string(json['mockTestId'] ?? json['mock_test_id']),
      examTitle: _string(json['examTitle'] ?? json['title'] ?? json['name']),
      score: _double(json['score'] ?? json['marksObtained']),
      percentage: _double(json['percentage'] ?? json['percent']),
      correct: _int(json['correct'] ?? json['correctAnswers']),
      incorrect: _int(json['incorrect'] ?? json['wrongAnswers']),
      attempted: _int(json['attempted'] ?? json['attemptedQuestions']),
      totalQuestions: _int(
          json['totalQuestions'] ?? json['questionCount'] ?? json['total']),
      completedAt: _dateOrNull(
          json['completedAt'] ?? json['completed_at'] ?? json['date']),
      durationMinutes: _int(
          json['durationMinutes'] ?? json['duration'] ?? json['timeTaken']),
    );
  }
}

Map<int, AnswerState> _decodeAnswers(dynamic value) {
  if (value is Map) {
    return value.entries
        .map((entry) {
          final key = entry.key;
          final intIndex = key is int ? key : int.tryParse(key.toString()) ?? 0;
          final val = entry.value;
          if (val is Map<String, dynamic>) {
            return MapEntry(intIndex, AnswerState.fromJson(val));
          }
          if (val is Map) {
            return MapEntry(
                intIndex, AnswerState.fromJson(Map<String, dynamic>.from(val)));
          }
          if (val is String) {
            return MapEntry(
              intIndex,
              AnswerState(selectedOptionKey: val),
            );
          }
          return null;
        })
        .whereType<MapEntry<int, AnswerState>>()
        .fold(<int, AnswerState>{}, (prev, entry) {
          prev[entry.key] = entry.value;
          return prev;
        });
  }
  return <int, AnswerState>{};
}

List<T> _decodeList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) factoryFn,
) {
  if (data is List) {
    return data
        .map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          }
          if (item is Map) {
            return Map<String, dynamic>.from(item);
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

List<TestQuestionOption> _buildFallbackOptions(
  Map<String, dynamic> json,
) {
  final candidates = <_OptionCandidate>[];
  final rawOptions = json['options'];
  if (rawOptions is Map) {
    rawOptions.forEach((rawKey, rawValue) {
      if (rawKey == null) return;
      _collectOptionCandidate(
        candidates: candidates,
        rawKey: rawKey.toString(),
        rawValue: rawValue,
      );
    });
  }

  json.forEach((rawKey, rawValue) {
    if (rawKey is! String) return;
    if (!_shouldConsiderFallbackKey(rawKey)) return;
    _collectOptionCandidate(
      candidates: candidates,
      rawKey: rawKey,
      rawValue: rawValue,
    );
  });

  if (candidates.isEmpty) {
    return const <TestQuestionOption>[];
  }

  final normalizedCorrect = _string(
    json['correctOption'] ??
        json['correctAnswer'] ??
        json['answerKey'] ??
        json['answer'] ??
        json['solutionKey'],
  )?.trim().toLowerCase();

  candidates.sort((a, b) => a.order.compareTo(b.order));
  return candidates
      .map((candidate) => candidate.toOption(normalizedCorrect))
      .toList();
}

void _collectOptionCandidate({
  required List<_OptionCandidate> candidates,
  required String rawKey,
  required dynamic rawValue,
}) {
  final label = _extractOptionLabel(rawValue);
  if (label == null || label.isEmpty) {
    return;
  }

  final key = rawKey.trim();
  if (key.isEmpty) return;

  final existingIndex = candidates.indexWhere(
    (candidate) => candidate.key.toLowerCase() == key.toLowerCase(),
  );
  if (existingIndex != -1) {
    return;
  }

  final suffix = _extractOptionSuffix(key);
  final order = _resolveOptionOrder(suffix, candidates.length);
  final hints = <String>{
    key.toLowerCase(),
    label.toLowerCase(),
  };

  if (suffix != null) {
    final normalizedSuffix = suffix.toLowerCase();
    hints.add(normalizedSuffix);
    hints.add('option$normalizedSuffix');
    hints.add('option_$normalizedSuffix');
    hints.add('option $normalizedSuffix');
    hints.add('choice$normalizedSuffix');
    hints.add('choice_$normalizedSuffix');
    hints.add('choice $normalizedSuffix');
    hints.add('answer$normalizedSuffix');
    hints.add('answer_$normalizedSuffix');
    hints.add('answer $normalizedSuffix');

    if (normalizedSuffix.length == 1) {
      final charCode = normalizedSuffix.codeUnitAt(0);
      if (charCode >= 97 && charCode <= 122) {
        final index = charCode - 96;
        hints.add(index.toString());
      }
    }
  }

  candidates.add(
    _OptionCandidate(
      key: key,
      label: label,
      order: order,
      hints: hints,
    ),
  );
}

String? _extractOptionLabel(dynamic rawValue) {
  if (rawValue == null) return null;
  if (rawValue is String) return rawValue.trim();
  if (rawValue is Map) {
    final map = rawValue is Map<String, dynamic>
        ? rawValue
        : Map<String, dynamic>.from(rawValue);
    final text = _string(
      map['label'] ??
          map['text'] ??
          map['value'] ??
          map['option'] ??
          map['answer'],
    );
    return text?.trim();
  }
  return _string(rawValue)?.trim();
}

String? _extractOptionSuffix(String key) {
  final lower = key.toLowerCase();
  final pattern = RegExp(r'^(option|choice|answer)[_\-]?([a-z0-9]+)$');
  final match = pattern.firstMatch(lower);
  if (match != null) {
    return match.group(2);
  }
  if (RegExp(r'^[a-z]$').hasMatch(lower)) {
    return lower;
  }
  if (RegExp(r'^\d+$').hasMatch(lower)) {
    return lower;
  }
  return null;
}

int _resolveOptionOrder(String? suffix, int fallbackIndex) {
  if (suffix == null) {
    return 1000 + fallbackIndex;
  }
  final numeric = int.tryParse(suffix);
  if (numeric != null) {
    return numeric;
  }
  if (suffix.length == 1) {
    final charCode = suffix.codeUnitAt(0);
    if (charCode >= 97 && charCode <= 122) {
      return 2000 + (charCode - 97);
    }
  }
  return 1000 + fallbackIndex;
}

bool _shouldConsiderFallbackKey(String key) {
  final lower = key.toLowerCase();
  if (lower == 'option' || lower == 'options') return false;
  if (lower.startsWith('selected')) return false;
  if (lower.contains('answerkey')) return false;
  if (lower.contains('correct')) return false;
  if (lower.contains('explanation')) return false;
  if (lower.contains('description')) return false;
  if (lower.contains('image')) return false;
  if (lower.contains('question')) return false;
  if (lower.contains('id')) return false;

  if (RegExp(r'^(option|choice|answer)[_\-]?[a-z0-9]+$').hasMatch(lower)) {
    return true;
  }
  if (RegExp(r'^[a-z]$').hasMatch(lower)) {
    return true;
  }
  if (RegExp(r'^\d+$').hasMatch(lower)) {
    return true;
  }
  return false;
}

class _OptionCandidate {
  const _OptionCandidate({
    required this.key,
    required this.label,
    required this.order,
    required this.hints,
  });

  final String key;
  final String label;
  final int order;
  final Set<String> hints;

  TestQuestionOption toOption(String? normalizedCorrect) {
    var isMatch = false;
    if (normalizedCorrect != null) {
      final normalized = normalizedCorrect.trim().toLowerCase();
      isMatch = hints.contains(normalized);
    }
    return TestQuestionOption(
      key: key,
      label: label,
      isCorrect: isMatch ? true : null,
    );
  }
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
  final lower = value.toString().toLowerCase();
  if (lower == 'true' || lower == 'yes' || lower == '1') return true;
  if (lower == 'false' || lower == 'no' || lower == '0') return false;
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
