import 'dart:convert';

import 'package:either_dart/either.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/errors/failure.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/http_service_provider.dart';

import '../../profile/data/models/favorite_category_model.dart';
import '../../profile/data/repo/category_repository.dart';
import '../model/course_models.dart';
import '../model/enrollment_models.dart';
import '../model/live_class_models.dart';
import '../service/course_service.dart';
import '../service/enrollment_service.dart';
import '../service/live_class_service.dart';

class CoursesState {
  final bool loadingPublic;
  final bool loadingSaved;
  final bool loadingDetails;
  final bool loadingCategories;
  final bool loadingSubjects;
  final bool loadingLecturers;
  final bool loadingMaterials;
  final bool loadingLectures;
  final bool loadingClasses;
  final bool loadingMockTests;
  final bool loadingEnrollments;
  final bool loadingLiveClasses;

  final Failure? publicError;
  final Failure? savedError;
  final Failure? detailsError;
  final Failure? categoriesError;
  final Failure? subjectsError;
  final Failure? lecturersError;
  final Failure? materialsError;
  final Failure? lecturesError;
  final Failure? classesError;
  final Failure? mockTestsError;
  final Failure? enrollmentsError;
  final Failure? liveClassesError;

  final List<CourseModel> publicCourses;
  final PagedMeta? publicMeta;
  final List<CourseModel> savedCourses;
  final PagedMeta? savedMeta;
  final bool savedLoaded;
  final Set<String> savedCourseIds;

  final String? currentSearch;
  final String? currentCategoryId;
  final CourseModel? selected;
  final Map<String, dynamic>? details;
  final List<ChildCategoryModel> categories;
  final List<SubjectModel> subjects;
  final List<LecturerModel> lecturers;
  final List<CourseMaterialModel> materials;
  final List<LectureModel> lectures;
  final List<CourseClassModel> classes;
  final List<MockTestModel> mockTests;

  final List<EnrollmentModel> enrollments;
  final bool enrollmentsLoaded;

  final List<LiveClassModel> liveClasses;
  final PagedMeta? liveClassesMeta;
  final bool liveClassesLoaded;
  final String? liveClassesStatus;
  final String? liveClassesCourseId;
  final String? liveClassesSubjectId;

  const CoursesState({
    this.loadingPublic = false,
    this.loadingSaved = false,
    this.loadingDetails = false,
    this.loadingCategories = false,
    this.loadingSubjects = false,
    this.loadingLecturers = false,
    this.loadingMaterials = false,
    this.loadingLectures = false,
    this.loadingClasses = false,
    this.loadingMockTests = false,
    this.loadingEnrollments = false,
    this.loadingLiveClasses = false,
    this.publicError,
    this.savedError,
    this.detailsError,
    this.categoriesError,
    this.subjectsError,
    this.lecturersError,
    this.materialsError,
    this.lecturesError,
    this.classesError,
    this.mockTestsError,
    this.enrollmentsError,
    this.liveClassesError,
    this.publicCourses = const [],
    this.publicMeta,
    this.savedCourses = const [],
    this.savedMeta,
    this.savedLoaded = false,
    this.savedCourseIds = const <String>{},
    this.currentSearch,
    this.currentCategoryId,
    this.selected,
    this.details,
    this.categories = const [],
    this.subjects = const [],
    this.lecturers = const [],
    this.materials = const [],
    this.lectures = const [],
    this.classes = const [],
    this.mockTests = const [],
    this.enrollments = const [],
    this.enrollmentsLoaded = false,
    this.liveClasses = const [],
    this.liveClassesMeta,
    this.liveClassesLoaded = false,
    this.liveClassesStatus,
    this.liveClassesCourseId,
    this.liveClassesSubjectId,
  });

  bool get isEnrolled {
    final payload = details;
    if (payload == null) return false;
    if (payload['isEnrolled'] == true) return true;
    final enrollment = payload['enrollmentDetails'];
    if (enrollment is Map<String, dynamic>) {
      final status = enrollment['status']?.toString().toLowerCase();
      return status == 'active' || status == 'completed';
    }
    return false;
  }

  CoursesState copyWith({
    bool? loadingPublic,
    bool? loadingSaved,
    bool? loadingDetails,
    bool? loadingCategories,
    bool? loadingSubjects,
    bool? loadingLecturers,
    bool? loadingMaterials,
    bool? loadingLectures,
    bool? loadingClasses,
    bool? loadingMockTests,
    bool? loadingEnrollments,
    bool? loadingLiveClasses,
    Failure? publicError,
    Failure? savedError,
    Failure? detailsError,
    Failure? categoriesError,
    Failure? subjectsError,
    Failure? lecturersError,
    Failure? materialsError,
    Failure? lecturesError,
    Failure? classesError,
    Failure? mockTestsError,
    Failure? enrollmentsError,
    Failure? liveClassesError,
    bool clearPublicError = false,
    bool clearSavedError = false,
    bool clearDetailsError = false,
    bool clearCategoriesError = false,
    bool clearSubjectsError = false,
    bool clearLecturersError = false,
    bool clearMaterialsError = false,
    bool clearLecturesError = false,
    bool clearClassesError = false,
    bool clearMockTestsError = false,
    bool clearEnrollmentsError = false,
    bool clearLiveClassesError = false,
    List<CourseModel>? publicCourses,
    PagedMeta? publicMeta,
    List<CourseModel>? savedCourses,
    PagedMeta? savedMeta,
    bool? savedLoaded,
    Set<String>? savedCourseIds,
    String? currentSearch,
    bool setCurrentSearch = false,
    String? currentCategoryId,
    bool setCurrentCategoryId = false,
    CourseModel? selected,
    Map<String, dynamic>? details,
    List<ChildCategoryModel>? categories,
    List<SubjectModel>? subjects,
    List<LecturerModel>? lecturers,
    List<CourseMaterialModel>? materials,
    List<LectureModel>? lectures,
    List<CourseClassModel>? classes,
    List<MockTestModel>? mockTests,
    List<EnrollmentModel>? enrollments,
    bool? enrollmentsLoaded,
    List<LiveClassModel>? liveClasses,
    PagedMeta? liveClassesMeta,
    bool? liveClassesLoaded,
    String? liveClassesStatus,
    bool setLiveClassesStatus = false,
    String? liveClassesCourseId,
    bool setLiveClassesCourseId = false,
    String? liveClassesSubjectId,
    bool setLiveClassesSubjectId = false,
  }) {
    return CoursesState(
      loadingPublic: loadingPublic ?? this.loadingPublic,
      loadingSaved: loadingSaved ?? this.loadingSaved,
      loadingDetails: loadingDetails ?? this.loadingDetails,
      loadingCategories: loadingCategories ?? this.loadingCategories,
      loadingSubjects: loadingSubjects ?? this.loadingSubjects,
      loadingLecturers: loadingLecturers ?? this.loadingLecturers,
      loadingMaterials: loadingMaterials ?? this.loadingMaterials,
      loadingLectures: loadingLectures ?? this.loadingLectures,
      loadingClasses: loadingClasses ?? this.loadingClasses,
      loadingMockTests: loadingMockTests ?? this.loadingMockTests,
      loadingEnrollments: loadingEnrollments ?? this.loadingEnrollments,
      loadingLiveClasses: loadingLiveClasses ?? this.loadingLiveClasses,
      publicError: clearPublicError ? null : (publicError ?? this.publicError),
      savedError: clearSavedError ? null : (savedError ?? this.savedError),
      detailsError: clearDetailsError
          ? null
          : (detailsError ?? this.detailsError),
      categoriesError: clearCategoriesError
          ? null
          : (categoriesError ?? this.categoriesError),
      subjectsError: clearSubjectsError
          ? null
          : (subjectsError ?? this.subjectsError),
      lecturersError: clearLecturersError
          ? null
          : (lecturersError ?? this.lecturersError),
      materialsError: clearMaterialsError
          ? null
          : (materialsError ?? this.materialsError),
      lecturesError: clearLecturesError
          ? null
          : (lecturesError ?? this.lecturesError),
      classesError: clearClassesError
          ? null
          : (classesError ?? this.classesError),
      mockTestsError: clearMockTestsError
          ? null
          : (mockTestsError ?? this.mockTestsError),
      enrollmentsError: clearEnrollmentsError
          ? null
          : (enrollmentsError ?? this.enrollmentsError),
      liveClassesError: clearLiveClassesError
          ? null
          : (liveClassesError ?? this.liveClassesError),
      publicCourses: publicCourses ?? this.publicCourses,
      publicMeta: publicMeta ?? this.publicMeta,
      savedCourses: savedCourses ?? this.savedCourses,
      savedMeta: savedMeta ?? this.savedMeta,
      savedLoaded: savedLoaded ?? this.savedLoaded,
      savedCourseIds: savedCourseIds ?? this.savedCourseIds,
      currentSearch: setCurrentSearch
          ? currentSearch
          : (currentSearch ?? this.currentSearch),
      currentCategoryId: setCurrentCategoryId
          ? currentCategoryId
          : (currentCategoryId ?? this.currentCategoryId),
      selected: selected ?? this.selected,
      details: details ?? this.details,
      categories: categories ?? this.categories,
      subjects: subjects ?? this.subjects,
      lecturers: lecturers ?? this.lecturers,
      materials: materials ?? this.materials,
      lectures: lectures ?? this.lectures,
      classes: classes ?? this.classes,
      mockTests: mockTests ?? this.mockTests,
      enrollments: enrollments ?? this.enrollments,
      enrollmentsLoaded: enrollmentsLoaded ?? this.enrollmentsLoaded,
      liveClasses: liveClasses ?? this.liveClasses,
      liveClassesMeta: liveClassesMeta ?? this.liveClassesMeta,
      liveClassesLoaded: liveClassesLoaded ?? this.liveClassesLoaded,
      liveClassesStatus: setLiveClassesStatus
          ? liveClassesStatus
          : (liveClassesStatus ?? this.liveClassesStatus),
      liveClassesCourseId: setLiveClassesCourseId
          ? liveClassesCourseId
          : (liveClassesCourseId ?? this.liveClassesCourseId),
      liveClassesSubjectId: setLiveClassesSubjectId
          ? liveClassesSubjectId
          : (liveClassesSubjectId ?? this.liveClassesSubjectId),
    );
  }
}

class CourseViewModel extends StateNotifier<CoursesState> {
  final CourseService _service;
  final CategoryRepository _categoryRepository;
  final EnrollmentService _enrollmentService;
  final LiveClassService _liveClassService;

  CourseViewModel(
    this._service,
    this._categoryRepository,
    this._enrollmentService,
    this._liveClassService,
  ) : super(const CoursesState());

  Future<void> loadCategories() async {
    if (state.loadingCategories || state.categories.isNotEmpty) return;
    state = state.copyWith(loadingCategories: true, clearCategoriesError: true);
    final result = await _categoryRepository.getCategoryHierarchy();
    state = result.fold(
      (failure) =>
          state.copyWith(loadingCategories: false, categoriesError: failure),
      (hierarchy) {
        final flattened = hierarchy
            .expand((node) => node.childCategories)
            .toList(growable: false);
        final unique = <String, ChildCategoryModel>{
          for (final category in flattened) category.id: category,
        };
        return state.copyWith(
          loadingCategories: false,
          categories: unique.values.toList(growable: false),
          categoriesError: null,
        );
      },
    );
  }

  Future<void> fetch({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
    bool applySearch = false,
    bool applyCategory = false,
  }) async {
    final trimmedSearch = search?.trim();
    final normalizedSearch = (trimmedSearch != null && trimmedSearch.isNotEmpty)
        ? trimmedSearch
        : null;
    final normalizedCategory = (categoryId != null && categoryId.isNotEmpty)
        ? categoryId
        : null;

    final nextSearch = applySearch ? normalizedSearch : state.currentSearch;
    final nextCategory = applyCategory
        ? normalizedCategory
        : state.currentCategoryId;

    state = state.copyWith(
      loadingPublic: true,
      clearPublicError: true,
      setCurrentSearch: applySearch,
      currentSearch: applySearch ? nextSearch : state.currentSearch,
      setCurrentCategoryId: applyCategory,
      currentCategoryId: applyCategory ? nextCategory : state.currentCategoryId,
    );

    final response = await _service.list(
      page: page,
      limit: limit,
      search: (nextSearch?.isNotEmpty ?? false) ? nextSearch : null,
      categoryId: (nextCategory?.isNotEmpty ?? false) ? nextCategory : null,
    );

    state = response.fold(
      (failure) => state.copyWith(loadingPublic: false, publicError: failure),
      (paged) {
        final savedIds = state.savedCourseIds;
        final incoming = paged.data
            .map(
              (course) => course.copyWith(
                isSaved: savedIds.contains(course.id) || course.isSaved,
              ),
            )
            .toList();
        final bool isFirstPage = page == 1;
        final updatedList = isFirstPage
            ? incoming
            : _mergeCourses(state.publicCourses, incoming);
        return state.copyWith(
          loadingPublic: false,
          publicCourses: updatedList,
          publicMeta: paged.meta,
          publicError: null,
          setCurrentSearch: applySearch,
          currentSearch: applySearch ? nextSearch : state.currentSearch,
          setCurrentCategoryId: applyCategory,
          currentCategoryId: applyCategory
              ? nextCategory
              : state.currentCategoryId,
        );
      },
    );
  }

  Future<void> loadNextPage() async {
    final meta = state.publicMeta;
    if (state.loadingPublic || meta == null || !(meta.hasNext)) return;
    await fetch(page: meta.page + 1, limit: meta.limit);
  }

  Future<void> fetchSaved({
    int page = 1,
    int limit = 10,
    String? search,
    bool force = false,
  }) async {
    final bool isFirstPage = page == 1;
    if (state.loadingSaved) return;
    if (!force && isFirstPage && state.savedLoaded) return;

    state = state.copyWith(loadingSaved: true, clearSavedError: true);

    final response = await _service.savedMine(
      page: page,
      limit: limit,
      search: (search?.isNotEmpty ?? false) ? search : null,
    );

    state = response.fold(
      (failure) => state.copyWith(loadingSaved: false, savedError: failure),
      (paged) {
        final incoming = paged.data
            .map((course) => course.copyWith(isSaved: true))
            .toList();
        final updatedSaved = isFirstPage
            ? incoming
            : _mergeCourses(state.savedCourses, incoming);
        final updatedIds = <String>{
          ...state.savedCourseIds,
          ...incoming.map((e) => e.id),
        };
        return state.copyWith(
          loadingSaved: false,
          savedCourses: updatedSaved,
          savedMeta: paged.meta,
          savedLoaded: true,
          savedCourseIds: updatedIds,
          savedError: null,
        );
      },
    );
  }

  Future<void> fetchEnrollments({bool force = false}) async {
    if (state.loadingEnrollments) return;
    if (!force && state.enrollmentsLoaded) return;

    state = state.copyWith(
      loadingEnrollments: true,
      clearEnrollmentsError: true,
    );

    final response = await _enrollmentService.myCourses();

    state = response.fold(
      (failure) =>
          state.copyWith(loadingEnrollments: false, enrollmentsError: failure),
      (enrollments) {
        final sorted = [...enrollments]
          ..sort((a, b) {
            DateTime? parse(String? value) {
              if (value == null || value.isEmpty) return null;
              return DateTime.tryParse(value);
            }

            final aDate = parse(a.enrollmentDate) ?? parse(a.createdAt);
            final bDate = parse(b.enrollmentDate) ?? parse(b.createdAt);
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });

        return state.copyWith(
          loadingEnrollments: false,
          enrollments: sorted,
          enrollmentsLoaded: true,
          enrollmentsError: null,
        );
      },
    );
  }

  Future<void> fetchLiveClasses({
    String status = 'ongoing',
    String? courseId,
    String? subjectId,
    int page = 1,
    int limit = 10,
    bool force = false,
  }) async {
    if (state.loadingLiveClasses) return;

    final previous = state;
    final sameFilters =
        previous.liveClassesLoaded &&
        previous.liveClassesStatus == status &&
        previous.liveClassesCourseId == courseId &&
        previous.liveClassesSubjectId == subjectId &&
        page == 1;

    if (!force && sameFilters) return;

    final isFirstPage = page == 1;
    final shouldReset = isFirstPage && (!sameFilters || force);

    state = state.copyWith(
      loadingLiveClasses: true,
      clearLiveClassesError: true,
      liveClasses: shouldReset
          ? const <LiveClassModel>[]
          : previous.liveClasses,
    );

    final response = await _enrollmentService.myLiveClasses(
      status: status,
      courseId: courseId,
      subjectId: subjectId,
      page: page,
      limit: limit,
    );

    state = response.fold(
      (failure) =>
          state.copyWith(loadingLiveClasses: false, liveClassesError: failure),
      (paged) {
        final base = (isFirstPage || shouldReset)
            ? <LiveClassModel>[]
            : previous.liveClasses;
        final merged = [...base, ...paged.data];
        final deduped = <String, LiveClassModel>{};
        for (final item in merged) {
          final key = item.id.isNotEmpty
              ? item.id
              : '${item.title}_${item.startTime?.millisecondsSinceEpoch ?? merged.indexOf(item)}';
          deduped[key] = item;
        }
        final nextList = deduped.values.toList(growable: false);
        return state.copyWith(
          loadingLiveClasses: false,
          liveClasses: nextList,
          liveClassesMeta: paged.meta ?? state.liveClassesMeta,
          liveClassesLoaded: true,
          liveClassesError: null,
          liveClassesStatus: status,
          setLiveClassesStatus: true,
          liveClassesCourseId: courseId,
          setLiveClassesCourseId: true,
          liveClassesSubjectId: subjectId,
          setLiveClassesSubjectId: true,
        );
      },
    );
  }

  Future<void> loadMoreLiveClasses() async {
    final meta = state.liveClassesMeta;
    if (state.loadingLiveClasses || meta == null || !meta.hasNext) return;
    await fetchLiveClasses(
      status: state.liveClassesStatus ?? 'ongoing',
      courseId: state.liveClassesCourseId,
      subjectId: state.liveClassesSubjectId,
      page: meta.page + 1,
      limit: meta.limit,
    );
  }

  Future<void> getById(String id) async {
    state = state.copyWith(loadingDetails: true, clearDetailsError: true);
    final response = await _service.byId(id);
    state = response.fold(
      (failure) => state.copyWith(loadingDetails: false, detailsError: failure),
      (course) => state.copyWith(
        loadingDetails: false,
        selected: course.copyWith(
          isSaved: state.savedCourseIds.contains(course.id) || course.isSaved,
        ),
        detailsError: null,
      ),
    );
  }

  Future<void> getBySlug(String slug) async {
    state = state.copyWith(loadingDetails: true, clearDetailsError: true);
    final response = await _service.bySlug(slug);
    state = response.fold(
      (failure) => state.copyWith(loadingDetails: false, detailsError: failure),
      (course) => state.copyWith(
        loadingDetails: false,
        selected: course.copyWith(
          isSaved: state.savedCourseIds.contains(course.id) || course.isSaved,
        ),
        detailsError: null,
      ),
    );
  }

  Future<void> getDetails(String id) async {
    state = state.copyWith(
      loadingDetails: true,
      clearDetailsError: true,
      loadingSubjects: true,
      loadingLecturers: true,
      loadingMaterials: true,
      loadingLectures: true,
      loadingClasses: true,
      loadingMockTests: true,
      clearSubjectsError: true,
      clearLecturersError: true,
      clearMaterialsError: true,
      clearLecturesError: true,
      clearClassesError: true,
      clearMockTestsError: true,
      subjects: const [],
      lecturers: const [],
      materials: const [],
      lectures: const [],
      classes: const [],
      mockTests: const [],
    );
    final response = await _service.details(id);
    // Debug: print raw response for course details API
    try {
      debugPrint('getDetails($id) response: $response');
    } catch (_) {}
    state = response.fold(
      (failure) => state.copyWith(
        loadingDetails: false,
        detailsError: failure,
        loadingSubjects: false,
        loadingLecturers: false,
        loadingMaterials: false,
        loadingLectures: false,
        loadingClasses: false,
        loadingMockTests: false,
        subjectsError: failure,
        lecturersError: failure,
        materialsError: failure,
        lecturesError: failure,
        classesError: failure,
        mockTestsError: failure,
      ),
      (payload) {
        try {
          final pretty = JsonEncoder.withIndent('  ').convert(payload);
          debugPrint('getDetails($id) payload:\n$pretty');
        } catch (_) {
          try {
            debugPrint('getDetails($id) payload: ${payload.toString()}');
          } catch (_) {}
        }
        final isSaved = payload['isSaved'] == true;
        final courseJson = payload['course'];
        CourseModel? detailedCourse;
        if (courseJson is Map<String, dynamic>) {
          detailedCourse = CourseModel.fromJson(
            courseJson,
          ).copyWith(isSaved: isSaved);
        }

        final subjectsList =
            (payload['syllabus'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(SubjectModel.fromJson)
                .toList(growable: false) ??
            const <SubjectModel>[];

        final lecturersList =
            (payload['lecturers'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(LecturerModel.fromJson)
                .toList(growable: false) ??
            const <LecturerModel>[];

        final materialsList =
            (payload['materials'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map((materialJson) {
                  final map = Map<String, dynamic>.from(materialJson);
                  map.putIfAbsent('courseId', () => id);
                  return CourseMaterialModel.fromJson(map);
                })
                .toList(growable: false) ??
            const <CourseMaterialModel>[];

        final lecturesList =
            (payload['lectures'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map((lectureJson) {
                  final map = Map<String, dynamic>.from(lectureJson);
                  map.putIfAbsent('courseId', () => id);
                  return LectureModel.fromJson(map);
                })
                .toList(growable: false) ??
            const <LectureModel>[];

        final sortedMaterials = [
          ...materialsList,
        ]..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));

        final sortedLectures = [
          ...lecturesList,
        ]..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));

        final classesList = _parseClassesFromPayload(payload);
        final mockTestsList = _parseMockTestsFromPayload(payload);

        final bool isEnrolledUser = _payloadIndicatesEnrollment(payload);

        final updatedIds = <String>{...state.savedCourseIds};
        if (isSaved) {
          updatedIds.add(id);
        } else {
          updatedIds.remove(id);
        }

        final updatedPublic = state.publicCourses
            .map(
              (course) => course.id == id
                  ? (detailedCourse ?? course.copyWith(isSaved: isSaved))
                  : course,
            )
            .toList();

        List<CourseModel> updatedSaved = state.savedCourses;
        if (isSaved) {
          if (detailedCourse != null) {
            final detailed = detailedCourse;
            if (updatedSaved.any((course) => course.id == id)) {
              updatedSaved = updatedSaved
                  .map((course) => course.id == id ? detailed : course)
                  .toList();
            } else {
              updatedSaved = [detailed, ...updatedSaved];
            }
          }
        } else {
          updatedSaved = updatedSaved
              .where((course) => course.id != id)
              .toList();
        }

        final nextState = state.copyWith(
          loadingDetails: false,
          details: payload,
          detailsError: null,
          selected: detailedCourse ?? state.selected,
          savedCourseIds: updatedIds,
          savedCourses: updatedSaved,
          publicCourses: updatedPublic,
          savedLoaded: true,
          loadingSubjects: false,
          loadingLecturers: false,
          loadingMaterials: false,
          loadingLectures: false,
          loadingClasses: false,
          loadingMockTests: false,
          clearSubjectsError: true,
          clearLecturersError: true,
          clearMaterialsError: true,
          clearLecturesError: true,
          clearClassesError: true,
          clearMockTestsError: true,
          subjects: subjectsList,
          lecturers: lecturersList,
          materials: sortedMaterials,
          lectures: sortedLectures,
          classes: classesList,
          mockTests: mockTestsList,
        );

        state = nextState;
        if (isEnrolledUser) {
          _loadEnrollmentCourseDetails(id);
        }
        return state;
      },
    );
  }

  bool _payloadIndicatesEnrollment(Map<String, dynamic> payload) {
    if (payload['isEnrolled'] == true) {
      return true;
    }
    final enrollment = payload['enrollmentDetails'];
    if (enrollment is Map<String, dynamic>) {
      final status = enrollment['status']?.toString().toLowerCase();
      if (status == 'active' || status == 'completed') {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadEnrollmentCourseDetails(String courseId) async {
    // fetch course details available only to enrolled students
    final res = await _enrollmentService.courseDetails(courseId);
    final previous = state;
    state = res.fold(
      (failure) {
        debugPrint(
          'enrollment course details not available: ${failure.message}',
        );
        return previous.copyWith(
          loadingClasses: false,
          loadingMockTests: false,
          classesError: failure,
          mockTestsError: previous.mockTests.isEmpty
              ? failure
              : previous.mockTestsError,
        );
      },
      (payload) {
        try {
          final pretty = JsonEncoder.withIndent('  ').convert(payload);
          debugPrint('enrolled course details($courseId):\n$pretty');
        } catch (_) {
          debugPrint(
            'enrolled course details($courseId): ${payload.toString()}',
          );
        }
        final classes = _parseClassesFromPayload(payload);
        final mockTests = _parseMockTestsFromPayload(payload);
        if (classes.isNotEmpty) {
          try {
            final pretty = JsonEncoder.withIndent(
              '  ',
            ).convert(classes.map((c) => c.raw).toList());
            debugPrint('enrolled classes parsed($courseId):\n$pretty');
          } catch (_) {}
        }
        if (mockTests.isNotEmpty) {
          try {
            final pretty = JsonEncoder.withIndent(
              '  ',
            ).convert(mockTests.map((m) => m.raw).toList());
            debugPrint('enrolled mock tests parsed($courseId):\n$pretty');
          } catch (_) {}
        }
        final merged = _mergeEnrollmentDetailsPayload(previous, payload);
        return previous.copyWith(
          details: merged,
          classes: classes.isNotEmpty ? classes : previous.classes,
          mockTests: mockTests.isNotEmpty ? mockTests : previous.mockTests,
          loadingClasses: false,
          loadingMockTests: false,
          clearClassesError: true,
          clearMockTestsError: true,
        );
      },
    );
  }

  Future<void> loadCourseExtras(String courseId) async {
    if (!state.isEnrolled) {
      return;
    }
    final futures = <Future<void>>[];
    if (state.subjects.isEmpty) {
      futures.add(_loadSubjects(courseId));
    }
    if (state.lecturers.isEmpty) {
      futures.add(_loadLecturers(courseId));
    }
    futures.add(_loadMaterials(courseId));
    futures.add(_loadLectures(courseId));
    await Future.wait(futures);
  }

  Future<void> refreshMaterials(String courseId, {bool force = true}) async {
    if (state.loadingMaterials) {
      debugPrint('materials fetch already running for $courseId');
      return;
    }
    if (!force && state.materials.isNotEmpty) {
      debugPrint('materials already cached for $courseId; skipping fetch');
      return;
    }
    debugPrint('Materials tab selected -> fetching materials for $courseId');
    await _loadMaterials(courseId);
  }

  Future<void> refreshLectures(String courseId, {bool force = true}) async {
    if (state.loadingLectures) {
      debugPrint('lectures fetch already running for $courseId');
      return;
    }
    if (!force && state.lectures.isNotEmpty) {
      debugPrint('lectures already cached for $courseId; skipping fetch');
      return;
    }
    debugPrint('Lectures tab selected -> fetching lectures for $courseId');
    await _loadLectures(courseId);
  }

  Future<void> refreshLecturers(String courseId, {bool force = true}) async {
    if (state.loadingLecturers) {
      debugPrint('lecturers fetch already running for $courseId');
      return;
    }
    if (!force && state.lecturers.isNotEmpty) {
      debugPrint('lecturers already cached for $courseId; skipping fetch');
      return;
    }
    debugPrint('Lecturers tab selected -> fetching lecturers for $courseId');
    await _loadLecturers(courseId);
  }

  Future<void> refreshClasses(String courseId, {bool force = true}) async {
    if (state.loadingClasses) {
      debugPrint('classes fetch already running for $courseId');
      return;
    }
    if (!force && state.classes.isNotEmpty) {
      debugPrint('classes already cached for $courseId; skipping fetch');
      return;
    }
    debugPrint('Classes tab selected -> fetching classes for $courseId');
    await _loadClasses(courseId);
  }

  Future<void> refreshMockTests(String courseId, {bool force = true}) async {
    if (state.loadingMockTests) {
      debugPrint('mock tests fetch already running for $courseId');
      return;
    }
    if (!force && state.mockTests.isNotEmpty) {
      debugPrint('mock tests already cached for $courseId; skipping fetch');
      return;
    }
    debugPrint('Mock Tests tab selected -> fetching tests for $courseId');
    await _loadMockTests(courseId);
  }

  Future<void> _loadSubjects(String courseId) async {
    state = state.copyWith(loadingSubjects: true, clearSubjectsError: true);
    final subjectsRes = await _service.subjectsByCourse(courseId);
    state = subjectsRes.fold(
      (failure) => state.copyWith(
        loadingSubjects: false,
        subjectsError: failure,
        subjects: const [],
      ),
      (subjectsList) => state.copyWith(
        loadingSubjects: false,
        subjects: subjectsList,
        subjectsError: null,
      ),
    );
  }

  Future<void> _loadLecturers(String courseId) async {
    state = state.copyWith(loadingLecturers: true, clearLecturersError: true);
    final lecturersRes = await _service.lecturersByCourse(courseId);
    state = lecturersRes.fold(
      (failure) => state.copyWith(
        loadingLecturers: false,
        lecturersError: failure,
        lecturers: const [],
      ),
      (lecturersList) => state.copyWith(
        loadingLecturers: false,
        lecturers: lecturersList,
        lecturersError: null,
      ),
    );
  }

  Future<void> _loadMaterials(String courseId) async {
    state = state.copyWith(loadingMaterials: true, clearMaterialsError: true);
    final materialsRes = await _service.materialsByCourse(courseId);
    state = materialsRes.fold(
      (failure) {
        debugPrint('materialsByCourse($courseId) failed: ${failure.message}');
        return state.copyWith(
          loadingMaterials: false,
          materialsError: failure,
          materials: const [],
        );
      },
      (materialsList) {
        materialsList.sort((a, b) {
          final orderA = a.displayOrder ?? 0;
          final orderB = b.displayOrder ?? 0;
          return orderA.compareTo(orderB);
        });
        try {
          final payloadForLog = materialsList
              .map(
                (material) => {
                  'id': material.id,
                  'title': material.materialTitle,
                  'subjectId': material.subjectId,
                  'displayOrder': material.displayOrder,
                },
              )
              .toList();
          final pretty = JsonEncoder.withIndent('  ').convert(payloadForLog);
          debugPrint('materialsByCourse($courseId) parsed payload:\n$pretty');
        } catch (_) {}
        return state.copyWith(
          loadingMaterials: false,
          materials: materialsList,
          materialsError: null,
        );
      },
    );
  }

  Future<void> _loadLectures(String courseId) async {
    if (state.subjects.isEmpty) {
      await _loadSubjects(courseId);
    }

    final subjects = state.subjects;
    if (subjects.isEmpty) {
      state = state.copyWith(
        loadingLectures: false,
        lecturesError: null,
        lectures: const [],
      );
      return;
    }

    state = state.copyWith(loadingLectures: true, clearLecturesError: true);

    final lectureMap = <String, LectureModel>{};

    for (final subject in subjects) {
      final lecturesRes = await _service.lecturesBySubject(subject.id);
      if (lecturesRes.isLeft) {
        final failure = lecturesRes.left;
        debugPrint(
          'lecturesBySubject(${subject.id}) failed: ${failure.message}',
        );
        state = state.copyWith(
          loadingLectures: false,
          lecturesError: failure,
          lectures: lectureMap.values.toList(growable: false),
        );
        return;
      }

      final lectures = lecturesRes.right;
      try {
        final payloadForLog = lectures
            .map(
              (lecture) => {
                'id': lecture.id,
                'name': lecture.name,
                'subjectId': lecture.subjectId,
                'displayOrder': lecture.displayOrder,
              },
            )
            .toList();
        final pretty = JsonEncoder.withIndent('  ').convert(payloadForLog);
        debugPrint('lecturesBySubject(${subject.id}) parsed payload:\n$pretty');
      } catch (_) {}

      for (final lecture in lectures) {
        lectureMap[lecture.id] = lecture;
      }
    }

    final aggregated = lectureMap.values.toList(growable: false)
      ..sort((a, b) {
        final orderA = a.displayOrder ?? 0;
        final orderB = b.displayOrder ?? 0;
        return orderA.compareTo(orderB);
      });

    state = state.copyWith(
      loadingLectures: false,
      lectures: aggregated,
      lecturesError: null,
    );
  }

  Future<void> _loadClasses(String courseId) async {
    state = state.copyWith(loadingClasses: true, clearClassesError: true);
    final loadingState = state;

    // CRITICAL: Call live classes API instead of course details
    // Live classes are NOT in course details API
    final res = await _liveClassService.getMyClasses(
      courseId: courseId,
      status: 'ongoing',
    );

    state = res.fold(
      (failure) {
        debugPrint(
          'Live classes for course $courseId failed: ${failure.message}',
        );
        return loadingState.copyWith(
          loadingClasses: false,
          classesError: failure,
        );
      },
      (liveClasses) {
        debugPrint(
          'Live classes for course $courseId: ${liveClasses.length} classes found',
        );

        // Convert LiveClassModel to CourseClassModel for compatibility
        final classes = liveClasses.map((liveClass) {
          return CourseClassModel(
            id: liveClass.id,
            title: liveClass.title,
            description: liveClass.description,
            startTime: liveClass.startTime,
            durationMinutes: liveClass.durationMinutes,
            durationLabel: liveClass.durationLabel,
            raw: {
              'id': liveClass.id,
              'title': liveClass.title,
              'description': liveClass.description,
              'startTime': liveClass.startTime?.toIso8601String(),
              'endTime': liveClass.endTime?.toIso8601String(),
              'durationMinutes': liveClass.durationMinutes,
              'durationLabel': liveClass.durationLabel,
              'status': liveClass.status,
            },
          );
        }).toList();

        return loadingState.copyWith(
          loadingClasses: false,
          classes: classes,
          classesError: null,
          clearClassesError: true,
        );
      },
    );
  }

  Future<void> _loadMockTests(String courseId) async {
    state = state.copyWith(loadingMockTests: true, clearMockTestsError: true);
    final loadingState = state;
    final res = await _service.mockTestsByCourse(courseId);
    state = res.fold(
      (failure) {
        debugPrint('mockTestsByCourse($courseId) failed: ${failure.message}');
        return loadingState.copyWith(
          loadingMockTests: false,
          mockTestsError: failure,
        );
      },
      (tests) {
        if (tests.isNotEmpty) {
          try {
            final pretty = JsonEncoder.withIndent(
              '  ',
            ).convert(tests.map((m) => m.raw).toList());
            debugPrint('mockTestsByCourse($courseId) parsed payload:\n$pretty');
          } catch (_) {}
        }
        return loadingState.copyWith(
          loadingMockTests: false,
          mockTests: tests,
          mockTestsError: null,
          clearMockTestsError: true,
        );
      },
    );
  }

  Future<Either<Failure, String?>> materialDownloadLink(
    String materialId,
  ) async {
    final response = await _service.downloadMaterial(materialId);
    return response.fold((failure) => Left(failure), (payload) {
      final url =
          payload['url'] ?? payload['fileUrl'] ?? payload['downloadUrl'];
      return Right(url?.toString());
    });
  }

  Future<Either<Failure, String?>> lectureWatchLink(String lectureId) async {
    final response = await _service.watchLecture(lectureId);
    return response.fold((failure) => Left(failure), (payload) {
      final url = payload['url'] ?? payload['videoUrl'] ?? payload['signedUrl'];
      return Right(url?.toString());
    });
  }

  Future<Either<Failure, bool>> toggleSave(
    String id, {
    required bool currentlySaved,
    CourseModel? course,
  }) async {
    final response = currentlySaved
        ? await _service.removeSaved(id)
        : await _service.save(id);
    return response.fold((failure) => Left(failure), (payload) {
      final isSaved = payload['isSaved'] == true;
      final updatedIds = <String>{...state.savedCourseIds};
      if (isSaved) {
        updatedIds.add(id);
      } else {
        updatedIds.remove(id);
      }

      final updatedPublic = state.publicCourses
          .map((item) => item.id == id ? item.copyWith(isSaved: isSaved) : item)
          .toList();

      List<CourseModel> updatedSaved = state.savedCourses;
      if (isSaved) {
        CourseModel? sourceCourse = course;
        sourceCourse ??= _findCourseById(state.publicCourses, id);
        if (sourceCourse != null) {
          final enriched = sourceCourse.copyWith(isSaved: true);
          if (updatedSaved.any((c) => c.id == id)) {
            updatedSaved = updatedSaved
                .map((c) => c.id == id ? enriched : c)
                .toList();
          } else {
            updatedSaved = [enriched, ...updatedSaved];
          }
        }
      } else {
        updatedSaved = updatedSaved.where((c) => c.id != id).toList();
      }

      state = state.copyWith(
        savedCourseIds: updatedIds,
        publicCourses: updatedPublic,
        savedCourses: updatedSaved,
        savedLoaded: true,
      );
      return Right(isSaved);
    });
  }

  Future<Either<Failure, bool>> checkSaved(String id) async {
    final response = await _service.isSaved(id);
    return response.fold((failure) => Left(failure), (isSaved) {
      final updatedIds = <String>{...state.savedCourseIds};
      if (isSaved) {
        updatedIds.add(id);
      } else {
        updatedIds.remove(id);
      }
      state = state.copyWith(
        savedCourseIds: updatedIds,
        publicCourses: state.publicCourses
            .map(
              (course) =>
                  course.id == id ? course.copyWith(isSaved: isSaved) : course,
            )
            .toList(),
      );
      return Right(isSaved);
    });
  }

  List<CourseModel> _mergeCourses(
    List<CourseModel> current,
    List<CourseModel> incoming,
  ) {
    final merged = List<CourseModel>.from(current);
    for (final course in incoming) {
      final index = merged.indexWhere((existing) => existing.id == course.id);
      if (index >= 0) {
        merged[index] = course;
      } else {
        merged.add(course);
      }
    }
    return merged;
  }

  CourseModel? _findCourseById(List<CourseModel> courses, String id) {
    for (final course in courses) {
      if (course.id == id) {
        return course;
      }
    }
    return null;
  }

  List<CourseClassModel> _parseClassesFromPayload(
    Map<String, dynamic> payload,
  ) {
    const candidateKeys = [
      'classes',
      'classSchedules',
      'classSchedule',
      'liveClasses',
    ];
    final map = <String, CourseClassModel>{};
    for (final key in candidateKeys) {
      final value = payload[key];
      if (value is List) {
        var index = 0;
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final model = CourseClassModel.fromJson(item);
            final identifier = model.id.isNotEmpty
                ? model.id
                : '${key}_${index}_${model.title}';
            map[identifier] = model;
          } else if (item is Map) {
            final model = CourseClassModel.fromJson(
              Map<String, dynamic>.from(item),
            );
            final identifier = model.id.isNotEmpty
                ? model.id
                : '${key}_${index}_${model.title}';
            map[identifier] = model;
          }
          index++;
        }
      }
    }
    final result = map.values.toList(growable: false);
    result.sort((a, b) {
      final aTime = a.startTime;
      final bTime = b.startTime;
      if (aTime == null && bTime == null) {
        return a.title.compareTo(b.title);
      }
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });
    return result;
  }

  List<MockTestModel> _parseMockTestsFromPayload(Map<String, dynamic> payload) {
    const candidateKeys = ['mockTests', 'mocktests', 'tests', 'exams'];
    final map = <String, MockTestModel>{};
    for (final key in candidateKeys) {
      final value = payload[key];
      if (value is List) {
        var index = 0;
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final model = MockTestModel.fromJson(item);
            final identifier = model.id.isNotEmpty
                ? model.id
                : '${key}_${index}_${model.title}';
            map[identifier] = model;
          } else if (item is Map) {
            final model = MockTestModel.fromJson(
              Map<String, dynamic>.from(item),
            );
            final identifier = model.id.isNotEmpty
                ? model.id
                : '${key}_${index}_${model.title}';
            map[identifier] = model;
          }
          index++;
        }
      }
    }
    final result = map.values.toList(growable: false);
    result.sort((a, b) => a.title.compareTo(b.title));
    return result;
  }

  Map<String, dynamic> _mergeEnrollmentDetailsPayload(
    CoursesState base,
    Map<String, dynamic> payload,
  ) {
    final merged = <String, dynamic>{...?base.details};
    final enrollmentData =
        payload['enrollment'] ?? payload['enrollmentDetails'] ?? payload;
    merged['enrollmentDetails'] = enrollmentData;
    final classesValue = payload['classes'] ?? payload['classSchedules'];
    if (classesValue != null) {
      merged['classes'] = classesValue;
    }
    final mockTestsValue =
        payload['mockTests'] ?? payload['mocktests'] ?? payload['tests'];
    if (mockTestsValue != null) {
      merged['mockTests'] = mockTestsValue;
    }
    return merged;
  }
}

final courseCategoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final http = ref.watch(httpServiceProvider);
  return CategoryRepositoryImpl(http);
});

final coursesViewModelProvider =
    StateNotifierProvider<CourseViewModel, CoursesState>((ref) {
      final service = ref.read(courseServiceProvider);
      final categoryRepo = ref.read(courseCategoryRepositoryProvider);
      final enrollmentService = ref.read(enrollmentServiceProvider);
      final liveClassService = ref.read(liveClassServiceProvider);
      return CourseViewModel(
        service,
        categoryRepo,
        enrollmentService,
        liveClassService,
      );
    });
