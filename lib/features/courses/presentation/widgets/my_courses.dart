import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../model/enrollment_models.dart';
import '../../view_model/course_view_model.dart';
import '../pages/enrolled_course_details_page.dart';

class MyCourses extends ConsumerStatefulWidget {
  const MyCourses({super.key});

  @override
  ConsumerState<MyCourses> createState() => _MyCoursesState();
}

class _MyCoursesState extends ConsumerState<MyCourses> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coursesViewModelProvider.notifier).fetchEnrollments(force: true);
    });
  }

  Future<void> _refresh() async {
    await ref
        .read(coursesViewModelProvider.notifier)
        .fetchEnrollments(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coursesViewModelProvider);
    final enrollments = state.enrollments;
    final isLoading = state.loadingEnrollments;
    final failure = state.enrollmentsError;

    if (isLoading && enrollments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (failure != null && enrollments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.failure),
            AppSpacing.verticalSpaceMedium,
            CText(
              failure.message,
              type: TextType.bodyLarge,
              textAlign: TextAlign.center,
              color: AppColors.failure,
            ),
            AppSpacing.verticalSpaceMedium,
            ReusableButton(
              text: 'Retry',
              onPressed: _refresh,
            ),
          ],
        ),
      );
    }

    if (enrollments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: [
            const Icon(Icons.school_outlined,
                size: 48, color: AppColors.gray500),
            AppSpacing.verticalSpaceMedium,
            const CText(
              'You have not enrolled in any courses yet.',
              type: TextType.bodyLarge,
              textAlign: TextAlign.center,
              color: AppColors.gray700,
            ),
            AppSpacing.verticalSpaceMedium,
            const CText(
              'Browse courses and start learning today!',
              type: TextType.bodySmall,
              textAlign: TextAlign.center,
              color: AppColors.gray600,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: enrollments.length,
        separatorBuilder: (_, __) => AppSpacing.verticalSpaceMedium,
        itemBuilder: (context, index) {
          final enrollment = enrollments[index];
          return _EnrollmentCourseCard(
            enrollment: enrollment,
            onOpen: () => _openCourse(context, enrollment),
          );
        },
      ),
    );
  }

  void _openCourse(BuildContext context, EnrollmentModel enrollment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnrolledCourseDetailsPage(
          courseId: enrollment.courseId,
          enrollment: enrollment,
        ),
      ),
    );
  }
}

class _EnrollmentCourseCard extends StatelessWidget {
  final EnrollmentModel enrollment;
  final VoidCallback onOpen;

  const _EnrollmentCourseCard({
    required this.enrollment,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final course = enrollment.course;
    final title = course?.courseTitle ?? 'Course';
    final progressPercentage =
        (enrollment.progress?.progressPercentage ?? 0).clamp(0, 100);
    final expiry = _parseDate(enrollment.expiryDate);

    // Calculate days until expiry
    String? expiryText;
    if (expiry != null) {
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;
      if (difference > 0) {
        expiryText = 'Expires In: $difference Days';
      } else if (difference == 0) {
        expiryText = 'Expires Today';
      } else {
        expiryText = 'Expired';
      }
    }

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Course Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomCachedNetworkImage(
                imageUrl: course?.courseImageUrl,
                size: Size(100, 100),
                fitStatus: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CText(
                    title,
                    type: TextType.bodyLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (expiryText != null) ...[
                    const SizedBox(height: 4),
                    CText(
                      expiryText,
                      type: TextType.bodySmall,
                      color: AppColors.gray600,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Progress Circle
            if (progressPercentage > 0)
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: progressPercentage / 100,
                        strokeWidth: 6,
                        backgroundColor: AppColors.gray300,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF1E3A5F), // Dark blue
                        ),
                      ),
                    ),
                    CText(
                      '${progressPercentage.toInt()}%',
                      type: TextType.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class _CourseThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _CourseThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CustomCachedNetworkImage(
        imageUrl: imageUrl,
        size: Size(96, 96),
        fitStatus: BoxFit.cover,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color bgColor;
    Color textColor;
    String label;

    switch (lower) {
      case 'completed':
        bgColor = AppColors.success.withOpacity(0.12);
        textColor = AppColors.success;
        label = 'Completed';
        break;
      case 'expired':
      case 'inactive':
        bgColor = AppColors.failure.withOpacity(0.12);
        textColor = AppColors.failure;
        label = 'Expired';
        break;
      default:
        bgColor = AppColors.primary.withOpacity(0.12);
        textColor = AppColors.primary;
        label = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CText(
        label,
        type: TextType.bodySmall,
        color: textColor,
      ),
    );
  }
}
