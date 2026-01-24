import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../courses/model/course_models.dart';
import '../../../view_model/mock_test_view_model.dart';

class TestSelectCourse extends ConsumerWidget {
  const TestSelectCourse({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mockTestViewModelProvider);
    final notifier = ref.read(mockTestViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Select Course'),
      body: RefreshIndicator(
        onRefresh: () => notifier.refreshCourses(),
        child: state.loadingCourses && state.courses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.courses.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(32.0),
                    children: [
                      const Icon(Icons.school_outlined,
                          size: 48, color: AppColors.gray400),
                      AppSpacing.verticalSpaceMedium,
                      const CText(
                        'No published courses available yet.',
                        type: TextType.bodyMedium,
                        color: AppColors.gray600,
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.verticalSpaceSmall,
                      const CText(
                        'Please check back later or explore new courses when they go live.',
                        type: TextType.bodySmall,
                        color: AppColors.gray500,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: state.courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final course = state.courses[index];
                      final selected = course.id == state.selectedCourseId;
                      return _CourseTile(
                        course: course,
                        selected: selected,
                        onTap: () {
                          notifier.selectCourse(course.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.course,
    required this.selected,
    required this.onTap,
  });

  final CourseModel course;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = course.courseTitle.isNotEmpty
        ? course.courseTitle
        : 'Course ${course.id}';
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.gray200,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CText(
                      title,
                      type: TextType.bodyLarge,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
              if (course.courseDescription?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: CText(
                    course.courseDescription!,
                    type: TextType.bodySmall,
                    color: AppColors.gray700,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              AppSpacing.verticalSpaceMedium,
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (course.categoryName?.isNotEmpty == true)
                    _MetaChip(label: 'Category', value: course.categoryName!),
                  if (course.durationHours != null)
                    _MetaChip(
                      label: 'Duration',
                      value: '${course.durationHours} hrs',
                    ),
                  if (course.validityDays != null)
                    _MetaChip(
                      label: 'Validity',
                      value: '${course.validityDays} days',
                    ),
                  if ((course.enrollmentCost ?? 0) > 0)
                    _MetaChip(
                      label: 'Price',
                      value: 'Rs. ${course.enrollmentCost}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CText(label, type: TextType.bodySmall, color: AppColors.gray600),
          AppSpacing.horizontalSpaceSmall,
          CText(value, type: TextType.bodySmall, color: AppColors.gray800),
        ],
      ),
    );
  }
}
