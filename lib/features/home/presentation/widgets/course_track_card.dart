import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../test/test.dart';
import '../../models/homepage_models.dart' as home_models;

class CourseTrackCard extends StatelessWidget {
  const CourseTrackCard({
    super.key,
    this.course,
    this.isLoading = false,
  });

  final home_models.LatestOngoingCourse? course;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
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
    final coverImage = course!.courseImageUrl ?? AppAssets.dummyNetImg;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.35),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomCachedNetworkImage(
                  imageUrl: coverImage,
                  fitStatus: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.gray900.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomCachedNetworkImage(
                        imageUrl: coverImage,
                        size: Size(110, 110),
                        fitStatus: BoxFit.cover,
                      ),
                    ),
                    AppSpacing.horizontalSpaceAverage,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryWithOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CText(
                              course!.courseTitle ?? 'Keep learning',
                              type: TextType.bodyMedium,
                              color: AppColors.white,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppSpacing.verticalSpaceSmall,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryWithOpacity(0.75),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CText(
                              '$completed of $totalLectures lectures completed',
                              type: TextType.bodySmall,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        AppSpacing.verticalSpaceMassive,
                        SizedBox(
                          height: 70,
                          width: 70,
                          child: ProgressCircle(percentage: progress),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
