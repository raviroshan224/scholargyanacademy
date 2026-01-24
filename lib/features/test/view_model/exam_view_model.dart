import 'package:flutter_riverpod/legacy.dart';

import '../../../config/services/remote_services/errors/failure.dart';
import '../models/exam_models.dart';
import '../service/exam_service.dart';

class ExamState {
  const ExamState({
    this.loadingList = false,
    this.loadingMore = false,
    this.listError,
    this.exams = const <ExamListItem>[],
    this.meta,
    this.search,
    this.status,
    this.category,
    this.sortBy,
    this.sortOrder,
    this.limit = 10,
    this.loadingDetail = false,
    this.detailError,
    this.selectedExam,
    this.selectedExamId,
  });

  final bool loadingList;
  final bool loadingMore;
  final Failure? listError;
  final List<ExamListItem> exams;
  final ExamListMeta? meta;
  final String? search;
  final String? status;
  final String? category;
  final String? sortBy;
  final String? sortOrder;
  final int limit;
  final bool loadingDetail;
  final Failure? detailError;
  final ExamDetail? selectedExam;
  final String? selectedExamId;

  bool get hasListError => listError != null;
  bool get hasDetailError => detailError != null;
  bool get canLoadMore => meta?.hasNextPage ?? false;

  ExamState copyWith({
    bool? loadingList,
    bool? loadingMore,
    Failure? listError,
    bool clearListError = false,
    List<ExamListItem>? exams,
    ExamListMeta? meta,
    bool clearMeta = false,
    String? search,
    bool setSearch = false,
    String? status,
    bool setStatus = false,
    String? category,
    bool setCategory = false,
    String? sortBy,
    bool setSortBy = false,
    String? sortOrder,
    bool setSortOrder = false,
    int? limit,
    bool? loadingDetail,
    Failure? detailError,
    bool clearDetailError = false,
    ExamDetail? selectedExam,
    bool clearSelectedExam = false,
    String? selectedExamId,
    bool clearSelectedExamId = false,
  }) {
    return ExamState(
      loadingList: loadingList ?? this.loadingList,
      loadingMore: loadingMore ?? this.loadingMore,
      listError: clearListError ? null : (listError ?? this.listError),
      exams: exams ?? this.exams,
      meta: clearMeta ? null : (meta ?? this.meta),
      search: setSearch ? search : (search ?? this.search),
      status: setStatus ? status : (status ?? this.status),
      category: setCategory ? category : (category ?? this.category),
      sortBy: setSortBy ? sortBy : (sortBy ?? this.sortBy),
      sortOrder: setSortOrder ? sortOrder : (sortOrder ?? this.sortOrder),
      limit: limit ?? this.limit,
      loadingDetail: loadingDetail ?? this.loadingDetail,
      detailError: clearDetailError ? null : (detailError ?? this.detailError),
      selectedExam:
          clearSelectedExam ? null : (selectedExam ?? this.selectedExam),
      selectedExamId:
          clearSelectedExamId ? null : (selectedExamId ?? this.selectedExamId),
    );
  }
}

class ExamViewModel extends StateNotifier<ExamState> {
  ExamViewModel(this._service) : super(const ExamState());

  final ExamService _service;

  Future<void> loadExamList({
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
      if (append && state.loadingMore) return;
      if (!append && state.loadingList) return;
    }

    final nextPage = page ?? (append ? (state.meta?.currentPage ?? 1) + 1 : 1);

    state = state.copyWith(
      loadingList: append ? state.loadingList : true,
      loadingMore: append,
      clearListError: true,
      clearMeta: !append,
      exams: append ? state.exams : state.exams,
      limit: limit ?? state.limit,
      setSearch: search != null,
      search: search,
      setStatus: status != null,
      status: status,
      setCategory: category != null,
      category: category,
      setSortBy: sortBy != null,
      sortBy: sortBy,
      setSortOrder: sortOrder != null,
      sortOrder: sortOrder,
    );

    final result = await _service.getExams(
      page: nextPage,
      limit: limit ?? state.limit,
      search: search ?? state.search,
      status: status ?? state.status,
      category: category ?? state.category,
      sortBy: sortBy ?? state.sortBy,
      sortOrder: sortOrder ?? state.sortOrder,
    );

    state = result.fold(
      (failure) => state.copyWith(
        loadingList: false,
        loadingMore: false,
        listError: failure,
      ),
      (payload) {
        final incoming = payload.items;
        final combined = append ? _mergeById(state.exams, incoming) : incoming;
        return state.copyWith(
          loadingList: false,
          loadingMore: false,
          exams: combined,
          meta: payload.meta,
        );
      },
    );
  }

  Future<void> refreshList() async {
    await loadExamList(force: true);
  }

  Future<void> loadExamDetails(String examId, {bool force = false}) async {
    if (!force && state.loadingDetail && state.selectedExamId == examId) {
      return;
    }

    if (!force &&
        state.selectedExamId == examId &&
        state.selectedExam != null) {
      return;
    }

    state = state.copyWith(
      loadingDetail: true,
      clearDetailError: true,
      clearSelectedExam: force,
      selectedExamId: examId,
    );

    final result = await _service.getExamDetails(examId);
    state = result.fold(
      (failure) => state.copyWith(
        loadingDetail: false,
        detailError: failure,
      ),
      (detail) => state.copyWith(
        loadingDetail: false,
        selectedExam: detail,
        selectedExamId: examId,
      ),
    );
  }

  Future<void> loadNextPage() async {
    if (!state.canLoadMore) return;
    await loadExamList(page: (state.meta?.currentPage ?? 1) + 1, append: true);
  }

  void clearDetailError() {
    state = state.copyWith(clearDetailError: true);
  }

  void clearListError() {
    state = state.copyWith(clearListError: true);
  }

  List<ExamListItem> _mergeById(
    List<ExamListItem> current,
    List<ExamListItem> incoming,
  ) {
    final map = {
      for (final item in current) item.id: item,
    };
    for (final item in incoming) {
      map[item.id] = item;
    }
    return map.values.toList();
  }
}

final examViewModelProvider =
    StateNotifierProvider<ExamViewModel, ExamState>((ref) {
  final service = ref.read(examServiceProvider);
  final notifier = ExamViewModel(service);
  notifier.loadExamList();
  return notifier;
});
