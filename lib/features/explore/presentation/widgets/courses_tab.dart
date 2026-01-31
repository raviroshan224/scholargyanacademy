import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../courses/presentation/pages/enrolled_course_details_page.dart';
import '../../../courses/view_model/course_view_model.dart';
import '../../../home/presentation/widgets/home_course_card.dart';
import '../../../test/view_model/exam_view_model.dart';

class CoursesTab extends ConsumerWidget {
  const CoursesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseState = ref.watch(coursesViewModelProvider);
    final courses = courseState.publicCourses;
    final examState = ref.watch(examViewModelProvider);
    final exam = examState.selectedExam;

    // If an exam is selected and has courses, show them instead
    final useExamCourses = exam != null && exam.courses.isNotEmpty;
    final examCourses = exam?.courses ?? <dynamic>[];

    return RefreshIndicator(
      onRefresh: () async {
        final notifier = ref.read(coursesViewModelProvider.notifier);
        final current = ref.read(coursesViewModelProvider);
        await notifier.fetch(
          page: 1,
          limit: current.publicMeta?.limit ?? 10,
          search: current.currentSearch,
          categoryId: current.currentCategoryId,
          applySearch: true,
          applyCategory: true,
        );
        await notifier.fetchSaved(force: true);
      },
      color: AppColors.primary,
      backgroundColor: AppColors.white,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 120 &&
              !courseState.loadingPublic &&
              (courseState.publicMeta?.hasNext ?? false)) {
            ref.read(coursesViewModelProvider.notifier).loadNextPage();
          }
          return false;
        },
        child: Builder(
          builder: (context) {
            // Initial Loading State
            if (courseState.loadingPublic &&
                courses.isEmpty &&
                !useExamCourses) {
              return _buildLoadingState();
            }

            // Error State
            if (courseState.publicError != null &&
                courses.isEmpty &&
                !useExamCourses) {
              return _buildErrorState(
                context,
                courseState.publicError!.message,
                () {
                  final notifier = ref.read(coursesViewModelProvider.notifier);
                  final current = ref.read(coursesViewModelProvider);
                  notifier.fetch(
                    page: 1,
                    limit: current.publicMeta?.limit ?? 10,
                    search: current.currentSearch,
                    categoryId: current.currentCategoryId,
                    applySearch: true,
                    applyCategory: true,
                  );
                },
              );
            }

            // Empty State
            if (courses.isEmpty && !useExamCourses) {
              return _buildEmptyState(context);
            }

            // Course List
            if (useExamCourses) {
              return _buildCourseList(
                context,
                examCourses,
                true, // isExamCourse
                false, // no loading for exam courses
              );
            }

            final itemCount =
                courses.length +
                ((courseState.loadingPublic &&
                        (courseState.publicMeta?.hasNext ?? false))
                    ? 2
                    : 0);

            return _buildCourseList(
              context,
              courses,
              false, // not exam course
              courseState.loadingPublic,
              itemCount: itemCount,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          CText(
            'Loading courses...',
            type: TextType.bodyMedium,
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              CText(
                'Oops! Something went wrong',
                type: TextType.headlineSmall,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CText(
                  message,
                  type: TextType.bodyMedium,
                  color: AppColors.gray600,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.gray600.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: AppColors.gray600.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              CText(
                'No Courses Found',
                type: TextType.headlineSmall,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: CText(
                  'We couldn\'t find any courses matching your criteria. Try adjusting your filters or search.',
                  type: TextType.bodyMedium,
                  color: AppColors.gray600,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseList(
    BuildContext context,
    List<dynamic> courses,
    bool isExamCourse,
    bool isLoading, {
    int? itemCount,
  }) {
    // Null safety guard
    if (courses.isEmpty && !isLoading) {
      return _buildEmptyState(context);
    }

    final totalItems = itemCount ?? courses.length;
    final rowCount = (totalItems / 2).ceil();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rowCount,
      itemBuilder: (context, index) {
        final courseIndex1 = index * 2;
        final courseIndex2 = index * 2 + 1;

        final isLoadingRow = courseIndex1 >= courses.length;

        if (isLoadingRow) {
          // Loading row
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(child: _buildLoadingCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildLoadingCard()),
              ],
            ),
          );
        } else {
          // Course row
          final course1 = courses[courseIndex1];
          final course2 = courseIndex2 < courses.length
              ? courses[courseIndex2]
              : null;

          // Null safety for courses
          if (course1 == null) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildCourseCard(context, course1, isExamCourse),
                ),
                const SizedBox(width: 12),
                if (course2 != null)
                  Expanded(
                    child: _buildCourseCard(context, course2, isExamCourse),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 200, // Match course card height
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gray600.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    dynamic course,
    bool isExamCourse,
  ) {
    // Null safety guard
    if (course == null || course.id == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Safe navigation
        if (course.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EnrolledCourseDetailsPage(courseId: course.id),
            ),
          );
        }
      },
      child: Hero(
        tag: 'course_${course.id}',
        child: Material(
          color: Colors.transparent,
          child: HomeCourseCard(
            title: isExamCourse
                ? (course.title ?? course.courseTitle ?? 'Untitled Course')
                : (course.courseTitle ?? 'Untitled Course'),
            subtitle: isExamCourse
                ? (course.description ?? '')
                : (course.courseDescription ?? ''),
            imagePath: isExamCourse
                ? (course.thumbnailUrl ?? AppAssets.errorImage)
                : ((course.courseIconUrl != null &&
                          course.courseIconUrl!.isNotEmpty)
                      ? course.courseIconUrl!
                      : (course.courseImageUrl ?? AppAssets.errorImage)),
            courseId: course.id,
            isSaved: isExamCourse
                ? (course.isSaved ?? false)
                : (course.isSaved ?? false),
            enrollmentCost: isExamCourse
                ? (course.enrollmentCost ?? course.price)
                : course.enrollmentCost,
            discountedPrice: isExamCourse ? null : course.discountedPrice,
            hasOffer: isExamCourse ? null : course.hasOffer,
            durationHours: isExamCourse
                ? (course.durationHours ?? course.duration)
                : course.durationHours,
            // validityDays: isExamCourse
            //     ? (course.validityDays ?? course.validity)
            //     : course.validityDays,
          ),
        ),
      ),
    );
  }
}
