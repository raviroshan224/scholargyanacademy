import 'package:flutter_riverpod/legacy.dart';

import '../../../config/services/remote_services/errors/failure.dart';
import '../models/homepage_models.dart';
import '../service/homepage_service.dart';

class HomepageState {
  const HomepageState({
    this.loading = false,
    this.error,
    this.data,
    this.updatingCategory = false,
    this.updateError,
    this.latestSelectedCategoryId,
  });

  final bool loading;
  final Failure? error;
  final HomepageResponse? data;
  final bool updatingCategory;
  final Failure? updateError;
  final String? latestSelectedCategoryId;

  List<Category> get preferredCategories =>
      data?.preferredCategories ?? const <Category>[];
  List<Course> get recommendedCourses =>
      data?.recommendedCourses ?? const <Course>[];
  List<Exam> get recommendedExams => data?.recommendedExams ?? const <Exam>[];
  LatestOngoingCourse? get latestOngoingCourse => data?.latestOngoingCourse;
  List<LiveClass> get liveClasses => data?.liveClasses ?? const <LiveClass>[];
  UpcomingExam? get upcomingExam => data?.upcomingExam;
  TopCategoryWithCourses? get topCategoryWithCourses =>
      data?.topCategoryWithCourses;
  UserProfile? get userProfile => data?.userProfile;

  bool get hasError => error != null;
  bool get hasData => data != null;

  HomepageState copyWith({
    bool? loading,
    Failure? error,
    bool clearError = false,
    HomepageResponse? data,
    bool? updatingCategory,
    Failure? updateError,
    bool clearUpdateError = false,
    String? latestSelectedCategoryId,
    bool setLatestSelectedCategoryId = false,
  }) {
    return HomepageState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
      updatingCategory: updatingCategory ?? this.updatingCategory,
      updateError: clearUpdateError ? null : (updateError ?? this.updateError),
      latestSelectedCategoryId: setLatestSelectedCategoryId
          ? latestSelectedCategoryId
          : (latestSelectedCategoryId ?? this.latestSelectedCategoryId),
    );
  }
}

class HomepageViewModel extends StateNotifier<HomepageState> {
  HomepageViewModel(this._service) : super(const HomepageState());

  final HomepageService _service;

  Future<void> getHomepageData({bool forceRefresh = false}) async {
    if (state.loading && !forceRefresh) return;

    state = state.copyWith(loading: true, clearError: true);
    final result = await _service.fetchHomepage();
    state = result.fold(
      (failure) => state.copyWith(
        loading: false,
        error: failure,
      ),
      (payload) {
        // Debug: print raw homepage payload for load/reload visibility
        // Using print so logs appear in debug console; replace with logger in production
        try {
          final user = payload.userProfile?.fullName ?? 'no-user';
          final recCount = payload.recommendedCourses.length;
          final prefCount = payload.preferredCategories.length;
          print(
              'Homepage payload loaded: user=$user recommended=$recCount preferred=$prefCount');
        } catch (e) {
          print('Homepage payload loaded (error reading fields): $e');
        }
        final newLatestCategoryId = state.latestSelectedCategoryId ??
            payload.topCategoryWithCourses?.categoryId ??
            (payload.preferredCategories.isNotEmpty
                ? payload.preferredCategories.first.id
                : null);
        return state.copyWith(
          loading: false,
          data: payload,
          setLatestSelectedCategoryId: true,
          latestSelectedCategoryId: newLatestCategoryId,
          clearError: true,
        );
      },
    );
  }

  Future<void> updateLatestCategory(String categoryId) async {
    final trimmed = categoryId.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final previousId = state.latestSelectedCategoryId;

    state = state.copyWith(
      updatingCategory: true,
      clearUpdateError: true,
      setLatestSelectedCategoryId: true,
      latestSelectedCategoryId: trimmed,
    );

    final result = await _service
        .updateLatestCategory(UpdateCategoryRequest(categoryId: trimmed));

    state = result.fold(
      (failure) => state.copyWith(
        updatingCategory: false,
        updateError: failure,
        setLatestSelectedCategoryId: true,
        latestSelectedCategoryId: previousId,
      ),
      (_) => state.copyWith(
        updatingCategory: false,
        clearUpdateError: true,
        setLatestSelectedCategoryId: true,
        latestSelectedCategoryId: trimmed,
      ),
    );

    if (result.isRight) {
      await getHomepageData(forceRefresh: true);
    }
  }
}

final homepageViewModelProvider =
    StateNotifierProvider<HomepageViewModel, HomepageState>((ref) {
  final service = ref.read(homepageServiceProvider);
  final notifier = HomepageViewModel(service);
  notifier.getHomepageData();
  return notifier;
});
