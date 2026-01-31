import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../courses/presentation/pages/enrolled_course_details_page.dart';
import '../../../courses/presentation/pages/video_player_page.dart';
import '../../../courses/service/course_service.dart';
import '../../models/homepage_models.dart' as home_models;

class CourseTrackCard extends ConsumerWidget {
  const CourseTrackCard({
    super.key,
    this.course,
    this.isLoading = false,
  });

  final home_models.LatestOngoingCourse? course;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (course == null) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: CText(
          'No ongoing course yet. Start learning to see progress here.',
          type: TextType.bodySmall,
          textAlign: TextAlign.center,
          color: AppColors.gray600,
        ),
      );
    }

    final progress = (course!.progressPercentage ?? 0).clamp(0, 100).round();
    final completed = course!.completedLectures ?? 0;
    final totalLectures = course!.totalLectures ?? 0;
    
    // Use lecture thumbnail if available, otherwise course image
    final String? lectureThumbnail = course!.lastAccessedLectureThumbnail;
    final String? coverImage = (lectureThumbnail != null && lectureThumbnail.isNotEmpty)
        ? lectureThumbnail
        : course!.courseImageUrl;
    
    final String? lectureTitle = course!.lastAccessedLectureTitle;
    final bool hasLecture = course!.lastAccessedLectureId != null && 
                            course!.lastAccessedLectureId!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background: either blurred image or attractive gradient placeholder
                Positioned.fill(
                  child: coverImage != null && coverImage.trim().isNotEmpty
                      ? ImageFiltered(
                          imageFilter:
                              ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                          child: CustomCachedNetworkImage(
                            imageUrl: coverImage,
                            fitStatus: BoxFit.cover,
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                            ),
                          ),
                        ),
                ),
                // Dark gradient overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromRGBO(0, 0, 0, 0.35),
                          Color.fromRGBO(0, 0, 0, 0.2),
                        ],
                      ),
                    ),
                  ),
                ),
                // Foreground content
                Row(
                  children: [
                    // Thumbnail with play icon overlay
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 110,
                              width: 110,
                              child: coverImage != null && coverImage.trim().isNotEmpty
                                  ? CustomCachedNetworkImage(
                                      imageUrl: coverImage,
                                      fitStatus: BoxFit.cover,
                                    )
                                  : Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF6A11CB),
                                            Color(0xFF2575FC),
                                          ],
                                          begin: Alignment.bottomLeft,
                                          end: Alignment.topRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: CText(
                                          course!.courseTitle ?? 'Course',
                                          type: TextType.bodySmall,
                                          color: AppColors.white,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          // Play icon overlay if lecture is available
                          if (hasLecture)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.black26,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14.0, horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CText(
                              course!.courseTitle ?? 'Keep learning',
                              type: TextType.bodyLarge,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (lectureTitle != null && lectureTitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              CText(
                                lectureTitle,
                                type: TextType.bodySmall,
                                color: Color.fromRGBO(255, 255, 255, 0.85),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            AppSpacing.verticalSpaceSmall,
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(255, 255, 255, 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CText(
                                    '$completed / $totalLectures',
                                    type: TextType.bodySmall,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress / 100.0,
                                    backgroundColor:
                                        Color.fromRGBO(255, 255, 255, 0.15),
                                    color: AppColors.primary,
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CText(
                                  '$progress%',
                                  type: TextType.bodySmall,
                                  color: AppColors.white,
                                ),
                              ],
                            ),
                            AppSpacing.verticalSpaceMedium,
                            Expanded(
                              child: CText(
                                hasLecture ? 'Resume Watching' : 'Continue where you left off.',
                                type: TextType.bodySmall,
                                fontWeight: hasLecture ? FontWeight.w600 : FontWeight.normal,
                                color: Color.fromRGBO(255, 255, 255, 0.9),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) async {
    final cid = course!.id;
    if (cid == null || cid.isEmpty) return;
    
    final lectureId = course!.lastAccessedLectureId;
    
    // If no lecture ID, fall back to course detail page
    if (lectureId == null || lectureId.isEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EnrolledCourseDetailsPage(courseId: cid)));
      return;
    }
    
    // Fetch watch URL and navigate to video player
    final courseService = ref.read(courseServiceProvider);
    final result = await courseService.watchLecture(lectureId);
    
    result.fold(
      (failure) {
        // On error, show snackbar and navigate to course detail
        AppMethods.showCustomSnackBar(
          context: context,
          message: failure.message.isNotEmpty 
              ? failure.message 
              : 'Failed to load video. Opening course details.',
          isError: true,
        );
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => EnrolledCourseDetailsPage(courseId: cid)));
      },
      (payload) {
        // Extract URL from payload
        String? watchUrl;
        const candidates = ['url', 'videoUrl', 'signedUrl', 'playbackUrl', 'streamUrl'];
        for (final key in candidates) {
          final value = payload[key];
          if (value is String && value.trim().isNotEmpty) {
            watchUrl = value.trim();
            break;
          }
        }
        
        if (watchUrl == null || watchUrl.isEmpty) {
          AppMethods.showCustomSnackBar(
            context: context,
            message: 'No playback URL available',
            isError: true,
          );
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EnrolledCourseDetailsPage(courseId: cid)));
          return;
        }
        
        // Navigate to video player with resume position
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VideoPlayerPage(
            url: watchUrl!,
            title: course!.lastAccessedLectureTitle ?? course!.courseTitle ?? 'Resume',
            lectureId: lectureId,
            thumbnailUrl: course!.lastAccessedLectureThumbnail,
            startPositionSeconds: 0,
          ),
        ));
      },
    );
  }
}
