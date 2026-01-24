// lib/features/test/view_model/test_session_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/widgets.dart'; // WidgetsBindingObserver
import 'package:shared_preferences/shared_preferences.dart';
import 'package:either_dart/either.dart'; // Either

import '../../../config/services/remote_services/errors/failure.dart';
import '../models/test_session_models.dart';
import '../service/test_session_service.dart';
import 'test_outcome_view_model.dart';

// ---------------------------------------------------------------------------
//  Test Session Lifecycle – strict finite‑state machine
// ---------------------------------------------------------------------------
enum TestSessionLifecycle {
  notStarted,
  starting,
  inProgress,
  paused,
  submitting,
  submitted,
  completed,
  expired,
  error,
}

typedef SessionLifecycle = TestSessionLifecycle; // compatibility alias

// ---------------------------------------------------------------------------
//  State object – holds immutable snapshot of the session
// ---------------------------------------------------------------------------
class TestSessionState {
  const TestSessionState({
    this.lifecycle = TestSessionLifecycle.notStarted,
    this.sessionId,
    this.session,
    this.lastError,
    this.recoveryLifecycle,
    this.history = const <TestHistoryItem>[],
    this.historyLoading = false,
    this.historyError,
  });

  final TestSessionLifecycle lifecycle;
  final String? sessionId;
  final TestSession? session;
  final Failure? lastError;
  final TestSessionLifecycle? recoveryLifecycle;
  final List<TestHistoryItem> history;
  final bool historyLoading;
  final Failure? historyError;

  // ---------------------------------------------------------------------
  //  Convenience getters – include compatibility for legacy UI code
  // ---------------------------------------------------------------------
  bool get isNotStarted => lifecycle == TestSessionLifecycle.notStarted;
  bool get isIdle => isNotStarted; // legacy name
  bool get isStarting => lifecycle == TestSessionLifecycle.starting;
  bool get isInProgress => lifecycle == TestSessionLifecycle.inProgress;
  bool get isPaused => lifecycle == TestSessionLifecycle.paused;
  bool get isSubmitting => lifecycle == TestSessionLifecycle.submitting;
  bool get isSubmitted => lifecycle == TestSessionLifecycle.submitted;
  bool get isCompleted => lifecycle == TestSessionLifecycle.completed;
  bool get isExpired => lifecycle == TestSessionLifecycle.expired;
  bool get isError => lifecycle == TestSessionLifecycle.error;
  // Compatibility getters for legacy UI checks (answering/navigating)
  bool get isAnswering => false;
  bool get isNavigating => false;

  TestSessionState copyWith({
    TestSessionLifecycle? lifecycle,
    bool clearLifecycle = false,
    String? sessionId,
    bool clearSessionId = false,
    TestSession? session,
    bool clearSession = false,
    Failure? lastError,
    bool clearLastError = false,
    TestSessionLifecycle? recoveryLifecycle,
    bool clearRecoveryLifecycle = false,
    List<TestHistoryItem>? history,
    bool clearHistory = false,
    bool? historyLoading,
    Failure? historyError,
    bool clearHistoryError = false,
  }) {
    return TestSessionState(
      lifecycle: clearLifecycle
          ? TestSessionLifecycle.notStarted
          : (lifecycle ?? this.lifecycle),
      sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
      session: clearSession ? null : (session ?? this.session),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      recoveryLifecycle: clearRecoveryLifecycle
          ? null
          : (recoveryLifecycle ?? this.recoveryLifecycle),
      history: clearHistory ? const <TestHistoryItem>[] : (history ?? this.history),
      historyLoading: historyLoading ?? this.historyLoading,
      historyError: clearHistoryError ? null : (historyError ?? this.historyError),
    );
  }
}

// ---------------------------------------------------------------------------
//  ViewModel – the single source of truth for the UI
// ---------------------------------------------------------------------------
class TestSessionViewModel extends StateNotifier<TestSessionState>
    with WidgetsBindingObserver {
  TestSessionViewModel(this._ref, this._service)
      : _isDisposed = false,
        _sessionGeneration = 0,
        super(const TestSessionState()) {
    WidgetsBinding.instance.addObserver(this);
    _loadPersistedSessionId();
    // Initialize anti‑cheat measures if needed (e.g., blockScreenshots())
  }

  final Ref _ref;
  final TestSessionService _service;

  bool _isDisposed;
  int _sessionGeneration;

  TestResultController get _resultController =>
      _ref.read(testResultControllerProvider.notifier);
  TestSolutionsController get _solutionsController =>
      _ref.read(testSolutionsControllerProvider.notifier);

  // ---------------------------------------------------------------------
  //  Load Test History
  // ---------------------------------------------------------------------
  Future<void> loadHistory({
    String? courseId,
    bool force = false,
  }) async {
    if (!force && state.historyLoading) {
      return;
    }

    _updateState((c) => c.copyWith(
          historyLoading: true,
          clearHistoryError: true,
        ));

    final result = await _service.getHistory(courseId: courseId);

    result.fold(
      (failure) {
        _updateState((c) => c.copyWith(
              historyLoading: false,
              historyError: failure,
            ));
      },
      (history) {
        _updateState((c) => c.copyWith(
              historyLoading: false,
              history: history,
              clearHistoryError: true,
            ));
      },
    );
  }

  // ---------------------------------------------------------------------
  //  Internal helpers
  // ---------------------------------------------------------------------
  DateTime? _pausedAt;
  static const Duration _backgroundThreshold = Duration(seconds: 10);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.paused) {
      _onAppPaused();
    } else if (appState == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  void _onAppPaused() {
    if (state.isInProgress) {
      _pausedAt = DateTime.now();
      _updateState((c) => c.copyWith(
          lifecycle: TestSessionLifecycle.paused, clearLastError: true));
    }
  }

  Future<void> _onAppResumed() async {
    if (state.isPaused && _pausedAt != null) {
      final offline = DateTime.now().difference(_pausedAt!);
      if (offline >= _backgroundThreshold || (state.session?.isExpired ?? false)) {
        await submitTest();
      } else {
        _updateState((c) => c.copyWith(
            lifecycle: TestSessionLifecycle.inProgress, clearLastError: true));
      }
      _pausedAt = null;
    }
  }

  // ---------------------------------------------------------------------
  //  Timer – derived from server‑provided endsAt
  // ---------------------------------------------------------------------
  Duration get remainingTime {
    final endsAt = state.session?.endsAt;
    if (endsAt == null) return Duration.zero;
    final diff = endsAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get canSubmit =>
      state.isInProgress && remainingTime > Duration.zero;

  // ---------------------------------------------------------------------
  //  Public API – start, load, answer, review, navigate, submit, history
  // ---------------------------------------------------------------------
  Future<TestSession?> startTest(String mockTestId) async {
    final generation = _beginNewSession();
    _resetOutcomeData();
    _updateState((c) => c.copyWith(
          lifecycle: TestSessionLifecycle.starting,
          clearSession: true,
          clearSessionId: true,
          clearLastError: true,
          recoveryLifecycle: TestSessionLifecycle.notStarted,
        ));

    final result = await _service.startSession(mockTestId);
    if (!_shouldApply(generation)) return null;

    // Persist sessionId immediately for crash/restart recovery
    await _persistSessionId(result);

    return result.fold(
      (failure) {
        _transitionToError(
          failure: failure,
          fallback: TestSessionLifecycle.notStarted,
        );
        return null;
      },
      (session) {
        final normalized = _normalizeSession(session);
        _applyBackendSession(
          normalized,
          lifecycle: _lifecycleForSession(normalized),
        );
        return normalized;
      },
    );
  }

  Future<void> loadSession(String sessionId, {bool force = false}) async {
    if (!force &&
        state.sessionId == sessionId &&
        state.session != null &&
        !state.isNotStarted) {
      return;
    }

    final generation = _beginNewSession();
    _resetOutcomeData();
    _updateState((c) => c.copyWith(
          lifecycle: TestSessionLifecycle.starting,
          sessionId: sessionId,
          clearSession: true,
          clearLastError: true,
        ));

    final result = await _service.getSession(sessionId);
    if (!_shouldApply(generation)) return;

    result.fold(
      (failure) {
        _transitionToError(
          failure: failure,
          fallback: TestSessionLifecycle.notStarted,
        );
      },
      (session) {
        final normalized = _normalizeSession(session);
        _applyBackendSession(
          normalized,
          lifecycle: _lifecycleForSession(normalized),
        );
      },
    );
  }

  Future<void> submitAnswer(int questionIndex, String selectedOption) async {
    final sessionId = state.sessionId;
    final activeSession = state.session;
    if (sessionId == null || activeSession == null) return;
    if (state.isStarting || state.isSubmitting || state.isAnswering) return;

    if (questionIndex < 0 ||
        activeSession.questions.isEmpty ||
        questionIndex >= activeSession.questions.length) {
      return;
    }

    final generation = _sessionGeneration;
    final previousSession = activeSession;

    _updateState((c) => c.copyWith(
          lifecycle: TestSessionLifecycle.inProgress,
          clearLastError: true,
        ));

    final request = AnswerSubmitRequest(
      questionIndex: questionIndex,
      selectedAnswer: selectedOption,
    );

    final result = await _service.submitAnswer(sessionId, request);
    if (!_shouldApply(generation)) return;

    result.fold(
      (failure) {
        _transitionToError(
          failure: failure,
          fallback: TestSessionLifecycle.inProgress,
          session: previousSession,
        );
      },
      (_) async {
        await _refreshSessionFromBackend(
          sessionId: sessionId,
          lifecycleAfterSuccess: TestSessionLifecycle.inProgress,
          generation: generation,
          fallbackSession: previousSession,
        );
      },
    );
  }

  Future<void> markForReview(int questionIndex, bool mark) async {
    final sessionId = state.sessionId;
    final activeSession = state.session;
    if (sessionId == null || activeSession == null) return;
    if (state.isStarting || state.isSubmitting || state.isAnswering) return;

    if (questionIndex < 0 ||
        activeSession.questions.isEmpty ||
        questionIndex >= activeSession.questions.length) {
      return;
    }

    final generation = _sessionGeneration;
    final previousSession = activeSession;

    _updateState((c) => c.copyWith(
          lifecycle: TestSessionLifecycle.inProgress,
          clearLastError: true,
        ));

    final request = MarkReviewRequest(
      questionIndex: questionIndex,
      markForReview: mark,
    );

    final result = await _service.toggleReview(sessionId, request);
    if (!_shouldApply(generation)) return;

    result.fold(
      (failure) {
        _transitionToError(
          failure: failure,
          fallback: TestSessionLifecycle.inProgress,
          session: previousSession,
        );
      },
      (_) async {
        await _refreshSessionFromBackend(
          sessionId: sessionId,
          lifecycleAfterSuccess: TestSessionLifecycle.inProgress,
          generation: generation,
          fallbackSession: previousSession,
        );
      },
    );
  }

  Future<void> navigateQuestion(int questionIndex) async {
    final sessionId = state.sessionId;
    final activeSession = state.session;
    if (sessionId == null || activeSession == null) return;
    if (state.isStarting || state.isSubmitting || state.isNavigating) return;

    if (questionIndex < 0) return;

    final generation = _sessionGeneration;
    final previousSession = activeSession;

    _updateState((c) => c.copyWith(
          lifecycle: TestSessionLifecycle.inProgress,
          clearLastError: true,
        ));

    final request = NavigateRequest(questionIndex: questionIndex);
    final result = await _service.navigate(sessionId, request);
    if (!_shouldApply(generation)) return;

    result.fold(
      (failure) {
        _transitionToError(
          failure: failure,
          fallback: TestSessionLifecycle.inProgress,
          session: previousSession,
        );
      },
      (_) async {
        await _refreshSessionFromBackend(
          sessionId: sessionId,
          lifecycleAfterSuccess: TestSessionLifecycle.inProgress,
          generation: generation,
          fallbackSession: previousSession,
        );
      },
    );
  }

  Future<void> submitTest() async {
    final sessionId = state.sessionId;
    final activeSession = state.session;
    if (sessionId == null || activeSession == null) return;
    if (state.isSubmitting || state.isStarting) return;

    final generation = _sessionGeneration;
    _updateState((c) => c.copyWith(
          lifecycle: TestSessionLifecycle.submitting,
          clearLastError: true,
        ));

    final result = await _service.submitTest(sessionId);
    if (!_shouldApply(generation)) return;

    result.fold(
      (failure) {
        _transitionToError(
          failure: failure,
          fallback: TestSessionLifecycle.inProgress,
          session: activeSession,
        );
      },
      (payload) {
        final completedSession = activeSession.copyWith(status: 'completed');
        _resultController.hydrate(payload);
        _solutionsController.reset();
        _updateState((c) => c.copyWith(
              lifecycle: TestSessionLifecycle.completed,
              session: completedSession,
              sessionId: completedSession.sessionId,
              clearLastError: true,
              clearRecoveryLifecycle: true,
            ));
      },
    );
  }

  Future<void> reloadHistory({bool force = false}) async {
    if (state.historyLoading && !force) return;

    _updateState((c) => c.copyWith(
          historyLoading: true,
          clearHistoryError: true,
        ));

    final result = await _service.getHistory();
    _updateState((c) => result.fold(
          (failure) => c.copyWith(
            historyLoading: false,
            historyError: failure,
          ),
          (history) => c.copyWith(
            historyLoading: false,
            history: history,
          ),
        ));
  }

  void clearLastError() {
    _updateState((c) => c.copyWith(
          clearLastError: true,
          clearRecoveryLifecycle: true,
        ));
  }

  void resetSession() {
    _beginNewSession();
    _resetOutcomeData();
    _updateState((_) => const TestSessionState());
  }

  void _resetOutcomeData() {
    _resultController.reset();
    _solutionsController.reset();
  }

  TestSession _normalizeSession(TestSession session) {
    final answers = Map<int, AnswerState>.from(session.answers);
    final questions = List<TestQuestion>.from(session.questions);

    final normalizedQuestions = <TestQuestion>[];
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final answer = answers[i] ?? answers[question.index];
      normalizedQuestions.add(
        question.copyWith(
          selectedOptionKey:
              answer?.selectedOptionKey ?? question.selectedOptionKey,
          isMarkedForReview:
              answer?.isMarkedForReview ?? question.isMarkedForReview,
        ),
      );
    }

    int? resolvedIndex = session.currentQuestionIndex;
    if (normalizedQuestions.isEmpty) {
      resolvedIndex = null;
    } else {
      resolvedIndex ??= 0;
      if (resolvedIndex < 0 || resolvedIndex >= normalizedQuestions.length) {
        resolvedIndex = 0;
      }
    }

    return session.copyWith(
      currentQuestionIndex: resolvedIndex,
      questions: normalizedQuestions,
      answers: answers,
    );
  }

  Future<void> _refreshSessionFromBackend({
    required String sessionId,
    required TestSessionLifecycle lifecycleAfterSuccess,
    required int generation,
    required TestSession? fallbackSession,
  }) async {
    final refreshed = await _service.getSession(sessionId);
    if (!_shouldApply(generation)) return;

    refreshed.fold(
      (failure) {
        _transitionToError(
          failure: failure,
          fallback: lifecycleAfterSuccess,
          session: fallbackSession,
        );
      },
      (session) {
        final normalized = _normalizeSession(session);
        _applyBackendSession(
          normalized,
          lifecycle: lifecycleAfterSuccess,
        );
      },
    );
  }

  void _applyBackendSession(
    TestSession session, {
    required TestSessionLifecycle lifecycle,
  }) {
    _updateState((c) => c.copyWith(
          lifecycle: lifecycle,
          session: session,
          sessionId: session.sessionId,
          clearLastError: true,
          clearRecoveryLifecycle: true,
        ));
  }

  TestSessionLifecycle _lifecycleForSession(TestSession session) {
    final status = (session.status ?? '').toLowerCase();
    if (status == 'completed' || status == 'submitted') {
      return TestSessionLifecycle.completed;
    }
    if (status == 'expired') {
      return TestSessionLifecycle.expired;
    }
    return TestSessionLifecycle.inProgress;
  }

  int _beginNewSession() {
    _sessionGeneration += 1;
    return _sessionGeneration;
  }

  bool _shouldApply(int generation) {
    return !_isDisposed && generation == _sessionGeneration;
  }

  Future<void> _persistSessionId(Either<Failure, TestSession> result) async {
    result.fold((_) {}, (session) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_test_session_id', session.sessionId);
    });
  }

  Future<void> _loadPersistedSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('active_test_session_id');
    if (id != null && state.sessionId == null) {
      await loadSession(id);
    }
  }

  void _transitionToError({
    required Failure failure,
    required TestSessionLifecycle fallback,
    TestSession? session,
  }) {
    _updateState((c) => c.copyWith(
          lifecycle: TestSessionLifecycle.error,
          lastError: failure,
          recoveryLifecycle: fallback,
          session: session ?? c.session,
          sessionId: session?.sessionId ?? c.sessionId,
        ));

    // Auto‑recover if a recovery lifecycle is set
    _updateState((c) {
      if (c.lifecycle != TestSessionLifecycle.error ||
          c.recoveryLifecycle == null) {
        return c;
      }
      return c.copyWith(
        lifecycle: c.recoveryLifecycle,
        clearRecoveryLifecycle: true,
      );
    });
  }

  void _updateState(TestSessionState Function(TestSessionState) builder) {
    if (_isDisposed) return;
    final next = builder(state);
    if (_isDisposed) return;
    super.state = next;
  }
}

// Provider – unchanged
final testSessionViewModelProvider =
    StateNotifierProvider<TestSessionViewModel, TestSessionState>((ref) {
  final service = ref.read(testSessionServiceProvider);
  return TestSessionViewModel(ref, service);
});
