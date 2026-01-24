import 'package:flutter_riverpod/legacy.dart';

import '../../../../config/services/remote_services/errors/failure.dart';
import '../../data/models/exam_models.dart';
import '../../data/repositories/exam_repository.dart';

class ExamListState {
  const ExamListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.exams = const <ExamSummary>[],
    this.meta,
    this.search,
    this.status = 'Active',
    this.category,
    this.sortBy,
    this.sortOrder = 'desc',
    this.page = 1,
    this.limit = 10,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final Failure? error;
  final List<ExamSummary> exams;
  final ExamListMeta? meta;
  final String? search;
  final String status;
  final String? category;
  final String? sortBy;
  final String? sortOrder;
  final int page;
  final int limit;

  bool get canLoadMore => (meta?.hasNext ?? false) && !isLoadingMore;

  ExamListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    Failure? error,
    bool clearError = false,
    List<ExamSummary>? exams,
    ExamListMeta? meta,
    bool clearMeta = false,
    String? search,
    bool setSearch = false,
    String? status,
    String? category,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) {
    return ExamListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      exams: exams ?? this.exams,
      meta: clearMeta ? null : (meta ?? this.meta),
      search: setSearch ? search : (search ?? this.search),
      status: status ?? this.status,
      category: category ?? this.category,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class ExamListViewModel extends StateNotifier<ExamListState> {
  ExamListViewModel(this._repository) : super(const ExamListState());

  final ExamRepository _repository;

  Future<void> loadExams({
    int? page,
    bool append = false,
    String? search,
    String? status,
    String? category,
    String? sortBy,
    String? sortOrder,
    int? limit,
    bool force = false,
  }) async {
    if (!force) {
      if (append && (state.isLoadingMore || !state.canLoadMore)) {
        return;
      }
      if (!append && state.isLoading) {
        return;
      }
    }

    final targetPage = page ?? (append ? state.page + 1 : 1);

    state = state.copyWith(
      isLoading: append ? state.isLoading : true,
      isLoadingMore: append,
      clearError: !append,
      page: targetPage,
      limit: limit ?? state.limit,
      setSearch: search != null,
      search: search,
      status: status ?? state.status,
      category: category ?? state.category,
      sortBy: sortBy ?? state.sortBy,
      sortOrder: sortOrder ?? state.sortOrder,
      clearMeta: !append,
      exams: append ? state.exams : state.exams,
    );

    final result = await _repository.fetchExamList(
      page: targetPage,
      limit: limit ?? state.limit,
      search: search ?? state.search,
      status: status ?? state.status,
      category: category ?? state.category,
      sortBy: sortBy ?? state.sortBy,
      sortOrder: sortOrder ?? state.sortOrder,
    );

    state = result.fold(
      (failure) => state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: failure,
      ),
      (payload) {
        final incoming = payload.items;
        final combined =
            append ? <ExamSummary>[...state.exams, ...incoming] : incoming;
        return state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          exams: combined,
          meta: payload.meta,
          page: payload.meta?.page ?? targetPage,
        );
      },
    );
  }

  Future<void> refresh() async {
    await loadExams(force: true);
  }
}

final examListViewModelProvider =
    StateNotifierProvider<ExamListViewModel, ExamListState>((ref) {
  final repository = ref.read(examRepositoryProvider);
  final notifier = ExamListViewModel(repository);
  notifier.loadExams();
  return notifier;
});
