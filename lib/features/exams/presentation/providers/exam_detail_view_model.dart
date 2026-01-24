import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../config/services/remote_services/errors/failure.dart';
import '../../data/models/exam_models.dart';
import '../../data/repositories/exam_repository.dart';

class ExamDetailState {
  const ExamDetailState({
    this.isLoading = false,
    this.error,
    this.detail,
    this.currentExamId,
  });

  final bool isLoading;
  final Failure? error;
  final ExamDetail? detail;
  final String? currentExamId;

  ExamDetailState copyWith({
    bool? isLoading,
    Failure? error,
    bool clearError = false,
    ExamDetail? detail,
    bool clearDetail = false,
    String? currentExamId,
  }) {
    return ExamDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      detail: clearDetail ? null : (detail ?? this.detail),
      currentExamId: currentExamId ?? this.currentExamId,
    );
  }
}

class ExamDetailViewModel extends StateNotifier<ExamDetailState> {
  ExamDetailViewModel(this._repository) : super(const ExamDetailState());

  final ExamRepository _repository;
  CancelToken? _activeToken;

  Future<void> loadExamDetail(String examId, {bool force = false}) async {
    if (!force && state.isLoading && state.currentExamId == examId) {
      return;
    }

    if (!force && state.detail != null && state.currentExamId == examId) {
      return;
    }

    _activeToken?.cancel('Replaced by a new request');
    _activeToken = CancelToken();

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentExamId: examId,
    );

    final requestToken = _activeToken;
    final result = await _repository.fetchExamDetail(
      examId: examId,
      cancelToken: requestToken,
    );

    state = result.fold(
      (failure) => state.copyWith(
        isLoading: false,
        error: failure,
      ),
      (detail) => state.copyWith(
        isLoading: false,
        detail: detail,
      ),
    );

    if (identical(requestToken, _activeToken)) {
      _activeToken = null;
    }
  }

  @override
  void dispose() {
    _activeToken?.cancel();
    super.dispose();
  }
}

final examDetailViewModelProvider =
    StateNotifierProvider<ExamDetailViewModel, ExamDetailState>((ref) {
  final repository = ref.read(examRepositoryProvider);
  return ExamDetailViewModel(repository);
});
