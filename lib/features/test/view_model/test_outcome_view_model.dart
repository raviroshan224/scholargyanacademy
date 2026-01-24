import 'package:flutter_riverpod/legacy.dart';

import '../../../config/services/remote_services/errors/failure.dart';
import '../models/test_session_models.dart';
import '../service/test_session_service.dart';

class TestResultState {
  const TestResultState({
    this.result,
    this.isLoading = false,
    this.error,
  });

  final TestResult? result;
  final bool isLoading;
  final Failure? error;

  TestResultState copyWith({
    TestResult? result,
    bool setResult = false,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return TestResultState(
      result: setResult ? result : (result ?? this.result),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TestResultController extends StateNotifier<TestResultState> {
  TestResultController(this._service) : super(const TestResultState());

  final TestSessionService _service;

  Future<void> fetch(String sessionId, {bool force = false}) async {
    if (sessionId.isEmpty) {
      return;
    }
    if (state.isLoading && !force) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    final response = await _service.getResult(sessionId);
    response.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (payload) {
        state = state.copyWith(
          isLoading: false,
          result: payload,
          setResult: true,
          clearError: true,
        );
      },
    );
  }

  void hydrate(TestResult result) {
    state = state.copyWith(
      result: result,
      setResult: true,
      isLoading: false,
      clearError: true,
    );
  }

  void reset() {
    state = const TestResultState();
  }
}

class TestSolutionsState {
  const TestSolutionsState({
    this.items = const <TestSolution>[],
    this.isLoading = false,
    this.error,
  });

  final List<TestSolution> items;
  final bool isLoading;
  final Failure? error;

  TestSolutionsState copyWith({
    List<TestSolution>? items,
    bool setItems = false,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return TestSolutionsState(
      items:
          setItems ? (items ?? const <TestSolution>[]) : (items ?? this.items),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TestSolutionsController extends StateNotifier<TestSolutionsState> {
  TestSolutionsController(this._service) : super(const TestSolutionsState());

  final TestSessionService _service;

  Future<void> fetch(String sessionId, {bool force = false}) async {
    if (sessionId.isEmpty) {
      return;
    }
    if (state.isLoading && !force) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    final response = await _service.getSolutions(sessionId);
    response.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (solutions) {
        state = state.copyWith(
          isLoading: false,
          items: solutions,
          setItems: true,
          clearError: true,
        );
      },
    );
  }

  void hydrate(List<TestSolution> items) {
    state = state.copyWith(
      items: items,
      setItems: true,
      isLoading: false,
      clearError: true,
    );
  }

  void reset() {
    state = const TestSolutionsState();
  }
}

final testResultControllerProvider =
    StateNotifierProvider<TestResultController, TestResultState>((ref) {
  final service = ref.read(testSessionServiceProvider);
  return TestResultController(service);
});

final testSolutionsControllerProvider =
    StateNotifierProvider<TestSolutionsController, TestSolutionsState>((ref) {
  final service = ref.read(testSessionServiceProvider);
  return TestSolutionsController(service);
});
