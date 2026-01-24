import 'package:flutter_riverpod/legacy.dart';

import '../../../config/services/remote_services/errors/failure.dart';
import '../../courses/model/course_models.dart';
import '../../courses/service/course_service.dart';
import '../models/mock_test_models.dart';
import '../service/mock_test_service.dart';

class MockTestState {
  const MockTestState({
    this.loadingCourses = false,
    this.coursesError,
    this.courses = const <CourseModel>[],
    this.selectedCourseId,
    this.loadingTests = false,
    this.testsError,
    this.tests = const <MockTest>[],
    this.meta,
    this.loadingDetail = false,
    this.detailError,
    this.selectedTest,
    this.selectedTestId,
    this.refreshing = false,
  });

  final bool loadingCourses;
  final Failure? coursesError;
  final List<CourseModel> courses;
  final String? selectedCourseId;
  final bool loadingTests;
  final Failure? testsError;
  final List<MockTest> tests;
  final MockTestMeta? meta;
  final bool loadingDetail;
  final Failure? detailError;
  final MockTest? selectedTest;
  final String? selectedTestId;
  final bool refreshing;

  bool get hasCourses => courses.isNotEmpty;
  bool get hasCoursesError => coursesError != null;
  bool get hasTestsError => testsError != null;
  bool get canLoadMore => (meta?.hasNext ?? false);

  MockTestState copyWith({
    bool? loadingCourses,
    Failure? coursesError,
    bool clearCoursesError = false,
    List<CourseModel>? courses,
    String? selectedCourseId,
    bool clearSelectedCourse = false,
    bool? loadingTests,
    Failure? testsError,
    bool clearTestsError = false,
    List<MockTest>? tests,
    MockTestMeta? meta,
    bool clearMeta = false,
    bool? loadingDetail,
    Failure? detailError,
    bool clearDetailError = false,
    MockTest? selectedTest,
    bool clearSelectedTest = false,
    String? selectedTestId,
    bool clearSelectedTestId = false,
    bool? refreshing,
  }) {
    return MockTestState(
      loadingCourses: loadingCourses ?? this.loadingCourses,
      coursesError:
          clearCoursesError ? null : (coursesError ?? this.coursesError),
      courses: courses ?? this.courses,
      selectedCourseId: clearSelectedCourse
          ? null
          : (selectedCourseId ?? this.selectedCourseId),
      loadingTests: loadingTests ?? this.loadingTests,
      testsError: clearTestsError ? null : (testsError ?? this.testsError),
      tests: tests ?? this.tests,
      meta: clearMeta ? null : (meta ?? this.meta),
      loadingDetail: loadingDetail ?? this.loadingDetail,
      detailError: clearDetailError ? null : (detailError ?? this.detailError),
      selectedTest:
          clearSelectedTest ? null : (selectedTest ?? this.selectedTest),
      selectedTestId:
          clearSelectedTestId ? null : (selectedTestId ?? this.selectedTestId),
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

class MockTestViewModel extends StateNotifier<MockTestState> {
  MockTestViewModel(this._service, this._courseService)
      : super(const MockTestState());

  final MockTestService _service;
  final CourseService _courseService;

  Future<void> loadCourses({bool force = false}) async {
    if (!force && (state.loadingCourses || state.courses.isNotEmpty)) {
      return;
    }
    state = state.copyWith(
      loadingCourses: true,
      clearCoursesError: true,
    );
    final result = await _courseService.list(page: 1, limit: 50);
    if (result.isLeft) {
      state = state.copyWith(
        loadingCourses: false,
        coursesError: result.left,
      );
      return;
    }
    final publishedCourses =
        result.right.data.where((course) => course.isPublished).toList();
    final selectedId = _resolveSelectedCourse(
      existingSelection: state.selectedCourseId,
      courses: publishedCourses,
    );

    state = state.copyWith(
      loadingCourses: false,
      courses: publishedCourses,
      selectedCourseId: selectedId,
    );

    if (selectedId != null) {
      await loadMockTests(courseId: selectedId, force: true);
    } else {
      state = state.copyWith(
        tests: const <MockTest>[],
        clearTestsError: true,
        clearMeta: true,
      );
    }
  }

  Future<void> refreshCourses() async {
    await loadCourses(force: true);
  }

  Future<void> selectCourse(String courseId) async {
    if (courseId == state.selectedCourseId) return;
    state = state.copyWith(
      selectedCourseId: courseId,
      clearTestsError: true,
      tests: const <MockTest>[],
      meta: null,
    );
    await loadMockTests(courseId: courseId, force: true);
  }

  Future<void> loadMockTests({
    String? courseId,
    bool append = false,
    int? page,
    int? limit,
    bool force = false,
  }) async {
    final targetCourseId = courseId ?? state.selectedCourseId;
    if (targetCourseId == null) return;

    if (!force) {
      if (append && state.loadingTests) return;
      if (!append && state.loadingTests && !state.refreshing) return;
    }

    final nextPage = page ?? (append ? (state.meta?.page ?? 1) + 1 : 1);

    state = state.copyWith(
      loadingTests: true,
      refreshing: !append && (force || page == null || nextPage == 1),
      clearTestsError: true,
      clearMeta: !append,
      tests: append
          ? state.tests
          : (force || page == null || nextPage == 1)
              ? const <MockTest>[]
              : state.tests,
    );

    final result = await _service.fetchMockTests(
      courseId: targetCourseId,
      page: nextPage,
      limit: limit,
    );

    state = result.fold(
      (failure) => state.copyWith(
        loadingTests: false,
        refreshing: false,
        testsError: failure,
      ),
      (payload) {
        final incoming = payload.tests
            .map((test) => test.courseId.isNotEmpty
                ? test
                : test.copyWith(courseId: targetCourseId))
            .toList();
        final combined = append ? _mergeById(state.tests, incoming) : incoming;
        final currentSelected = state.selectedTest;
        final updatedSelected = currentSelected == null
            ? null
            : _findTestById(currentSelected.id, combined) ?? currentSelected;
        return state.copyWith(
          loadingTests: false,
          refreshing: false,
          tests: combined,
          meta: payload.meta,
          selectedTest: updatedSelected,
          selectedTestId: updatedSelected?.id ?? state.selectedTestId,
        );
      },
    );
  }

  Future<void> refreshTests() async {
    await loadMockTests(force: true);
  }

  Future<void> loadNextPage() async {
    if (!state.canLoadMore || state.selectedCourseId == null) return;
    await loadMockTests(
      append: true,
      page: (state.meta?.page ?? 1) + 1,
    );
  }

  Future<void> loadMockTestDetail(String mockTestId, {bool force = false}) async {
    final courseId = state.selectedCourseId;
    if (courseId == null) return;

    // Skip cache if force refresh is requested (e.g., after payment)
    if (!force) {
      final cached = _findTestById(mockTestId);
      if (cached != null) {
        state = state.copyWith(
          clearDetailError: true,
          selectedTest: cached,
          selectedTestId: mockTestId,
          loadingDetail: false,
        );
        return;
      }
    }

    state = state.copyWith(
      loadingDetail: true,
      clearDetailError: true,
      selectedTestId: mockTestId,
    );
    final result = await _service.fetchMockTestDetail(
      courseId: courseId,
      mockTestId: mockTestId,
    );
    state = result.fold(
      (failure) => state.copyWith(
        loadingDetail: false,
        detailError: failure,
      ),
      (test) {
        final normalizedTest =
            test.courseId.isNotEmpty ? test : test.copyWith(courseId: courseId);
        final mergedTests = _mergeById(state.tests, [normalizedTest]);
        return state.copyWith(
          loadingDetail: false,
          selectedTest: normalizedTest,
          selectedTestId: mockTestId,
          tests: mergedTests,
        );
      },
    );
  }

  void clearDetail() {
    state = state.copyWith(
      clearDetailError: true,
      clearSelectedTest: true,
      clearSelectedTestId: true,
    );
  }

  void updateTestAccess({
    required String mockTestId,
    bool? canTakeTest,
    bool? isPurchased,
  }) {
    var testsChanged = false;
    final updatedTests = state.tests.map((test) {
      if (_matches(mockTestId, test)) {
        final nextCanTake = canTakeTest ?? test.canTakeTest;
        final nextPurchased = isPurchased ?? test.isPurchased;
        if (nextCanTake == test.canTakeTest &&
            nextPurchased == test.isPurchased) {
          return test;
        }
        testsChanged = true;
        return test.copyWith(
          canTakeTest: nextCanTake,
          isPurchased: nextPurchased,
        );
      }
      return test;
    }).toList();

    final currentSelected = state.selectedTest;
    MockTest? updatedSelected = currentSelected;
    if (currentSelected != null && _matches(mockTestId, currentSelected)) {
      final nextCanTake = canTakeTest ?? currentSelected.canTakeTest;
      final nextPurchased = isPurchased ?? currentSelected.isPurchased;
      if (nextCanTake != currentSelected.canTakeTest ||
          nextPurchased != currentSelected.isPurchased) {
        updatedSelected = currentSelected.copyWith(
          canTakeTest: nextCanTake,
          isPurchased: nextPurchased,
        );
      }
    }

    if (!testsChanged && updatedSelected == currentSelected) {
      return;
    }

    state = state.copyWith(
      tests: testsChanged ? updatedTests : state.tests,
      selectedTest: updatedSelected,
      selectedTestId: updatedSelected?.id ?? state.selectedTestId,
    );
  }

  String? _resolveSelectedCourse({
    required String? existingSelection,
    required List<CourseModel> courses,
  }) {
    if (courses.isEmpty) return null;
    if (existingSelection != null &&
        courses.any((course) => course.id == existingSelection)) {
      return existingSelection;
    }
    final firstCourse = courses.firstWhere(
      (course) => course.id.isNotEmpty,
      orElse: () => courses.first,
    );
    return firstCourse.id.isNotEmpty ? firstCourse.id : existingSelection;
  }

  List<MockTest> _mergeById(
    List<MockTest> current,
    List<MockTest> incoming,
  ) {
    final map = {
      for (final item in current) item.id: item,
    };
    for (final item in incoming) {
      map[item.id] = item;
    }
    return map.values.toList();
  }

  MockTest? _findTestById(String mockTestId, [List<MockTest>? source]) {
    final tests = source ?? state.tests;
    for (final test in tests) {
      if (_matches(mockTestId, test)) {
        return test;
      }
    }
    return null;
  }

  bool _matches(String targetId, MockTest test) {
    if (test.id == targetId) return true;
    final extra = test.extra;
    if (extra == null) return false;
    final slug = extra['slug']?.toString();
    final legacyId = extra['mockTestId']?.toString();
    return slug == targetId || legacyId == targetId;
  }
}

final mockTestViewModelProvider =
    StateNotifierProvider<MockTestViewModel, MockTestState>((ref) {
  final service = ref.read(mockTestServiceProvider);
  final courseService = ref.read(courseServiceProvider);
  final notifier = MockTestViewModel(service, courseService);
  notifier.loadCourses();
  return notifier;
});
