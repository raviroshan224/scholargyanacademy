import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../model/course_models.dart';
import '../../service/course_service.dart';
import '../pages/enrolled_course_details_page.dart';

class SavedCoursesWidget extends ConsumerStatefulWidget {
  const SavedCoursesWidget({super.key});

  @override
  ConsumerState<SavedCoursesWidget> createState() => _SavedCoursesWidgetState();
}

class _SavedCoursesWidgetState extends ConsumerState<SavedCoursesWidget> {
  bool _isLoading = false;
  String? _errorMessage;
  List<CourseModel> _savedCourses = [];
  int _currentPage = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchSavedCourses();
  }

  Future<void> _fetchSavedCourses({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _savedCourses = [];
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = ref.read(courseServiceProvider);
    final result = await service.savedMine(page: _currentPage, limit: _limit);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (pagedCourses) {
        setState(() {
          _isLoading = false;
          _savedCourses =
              pagedCourses.data; // PagedCourses uses `data` for the list
        });
      },
    );
  }

  Future<void> _unsaveCourse(String courseId) async {
    final service = ref.read(courseServiceProvider);
    final result = await service.removeSaved(courseId);

    result.fold(
      (failure) {
        if (mounted) {
          AppMethods.showCustomSnackBar(
            context: context,
            message: failure.message,
            isError: true,
          );
        }
      },
      (_) {
        // Remove from local list
        setState(() {
          _savedCourses.removeWhere((course) => course.id == courseId);
        });
        if (mounted) {
          AppMethods.showCustomSnackBar(
            context: context,
            message: 'Course removed from saved',
            isError: false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _savedCourses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _savedCourses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchSavedCourses(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.failure),
            AppSpacing.verticalSpaceMedium,
            CText(
              _errorMessage!,
              type: TextType.bodyLarge,
              textAlign: TextAlign.center,
              color: AppColors.failure,
            ),
            AppSpacing.verticalSpaceMedium,
            ReusableButton(
              text: 'Retry',
              onPressed: () => _fetchSavedCourses(refresh: true),
            ),
          ],
        ),
      );
    }

    if (_savedCourses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchSavedCourses(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: [
            const Icon(Icons.bookmark_outline,
                size: 48, color: AppColors.gray500),
            AppSpacing.verticalSpaceMedium,
            const CText(
              'No saved courses yet',
              type: TextType.bodyLarge,
              textAlign: TextAlign.center,
              color: AppColors.gray700,
            ),
            AppSpacing.verticalSpaceMedium,
            const CText(
              'Save courses to access them quickly later!',
              type: TextType.bodySmall,
              textAlign: TextAlign.center,
              color: AppColors.gray600,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchSavedCourses(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _savedCourses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final course = _savedCourses[index];
          return _SavedCourseCard(
            course: course,
            onTap: () => _navigateToCourseDetails(course),
            onUnsave: () => _unsaveCourse(course.id),
          );
        },
      ),
    );
  }

  void _navigateToCourseDetails(CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnrolledCourseDetailsPage(
          courseId: course.id,
        ),
      ),
    );
  }
}

class _SavedCourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SavedCourseCard({
    required this.course,
    required this.onTap,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: CustomCachedNetworkImage(
                imageUrl: course.courseImageUrl,
                size: Size(100, 100),
                fitStatus: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),

            // Course Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CText(
                      course.courseTitle,
                      type: TextType.titleMedium,
                      color: AppColors.black,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.gray600,
                        ),
                        const SizedBox(width: 4),
                        CText(
                          '${course.durationHours ?? 0} Hours',
                          type: TextType.bodySmall,
                          color: AppColors.gray600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CText(
                      'Rs. ${course.enrollmentCost ?? 0}',
                      type: TextType.titleMedium,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ),

            // Bookmark Icon
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.bookmark,
                  color: AppColors.primary,
                  size: 24,
                ),
                onPressed: onUnsave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
