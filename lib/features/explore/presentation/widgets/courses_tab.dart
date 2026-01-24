import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../courses/presentation/pages/enrolled_course_details_page.dart';
import '../../../courses/view_model/course_view_model.dart';
import '../../../home/home.dart';
import '../../../test/view_model/exam_view_model.dart';

class CoursesTab extends ConsumerWidget {
  const CoursesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseState = ref.watch(coursesViewModelProvider);
    final courses = courseState.publicCourses;
    final examState = ref.watch(examViewModelProvider);
    final exam = examState.selectedExam;

    // if an exam is selected and has courses, show them instead
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
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 16),
          child: Builder(
            builder: (context) {
              if (courseState.loadingPublic &&
                  courses.isEmpty &&
                  !useExamCourses) {
                return const Center(child: CircularProgressIndicator());
              }

              if (courseState.publicError != null &&
                  courses.isEmpty &&
                  !useExamCourses) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child:
                        Center(child: CText(courseState.publicError!.message)),
                  ),
                );
              }

              if (courses.isEmpty && !useExamCourses) {
                return const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 200,
                    child: Center(child: CText('No courses found')),
                  ),
                );
              }

              if (useExamCourses) {
                final itemCount = examCourses.length;
                return GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 3 / 4.1,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    final course = examCourses[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EnrolledCourseDetailsPage(
                              courseId: course.id,
                            ),
                          ),
                        );
                      },
                      child: HomeCourseCard(
                        title: course.title ?? course.courseTitle ?? '',
                        subtitle: course.description ?? '',
                        imagePath: course.thumbnailUrl ?? AppAssets.errorImage,
                        courseId: course.id,
                        isSaved: course.isSaved ?? false,
                        enrollmentCost: course.enrollmentCost ?? course.price,
                        durationHours: course.durationHours ?? course.duration,
                        validityDays: course.validityDays ?? course.validity,
                        isGrid: true,
                      ),
                    );
                  },
                );
              }

              final itemCount = courses.length +
                  ((courseState.loadingPublic &&
                          (courseState.publicMeta?.hasNext ?? false))
                      ? 1
                      : 0);

              return GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 3 / 4.1,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index >= courses.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final course = courses[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EnrolledCourseDetailsPage(
                            courseId: course.id,
                          ),
                        ),
                      );
                    },
                    child: HomeCourseCard(
                      title: course.courseTitle,
                      subtitle: course.courseDescription ?? '',
                      imagePath: course.courseImageUrl ?? AppAssets.errorImage,
                      courseId: course.id,
                      isSaved: course.isSaved,
                      enrollmentCost: course.enrollmentCost,
                      durationHours: course.durationHours,
                      validityDays: course.validityDays,
                      isGrid: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
