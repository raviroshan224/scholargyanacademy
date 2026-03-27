import 'package:flutter/material.dart';
import 'package:scholarsgyanacademy/features/courses/presentation/pages/listed_course_details_page.dart';

import '../../../../core/core.dart';
import '../../models/homepage_models.dart' as home_models;

class GrabTheDealList extends StatelessWidget {
  const GrabTheDealList({super.key, this.topCategory, this.isLoading = false});

  final home_models.TopCategoryWithCourses? topCategory;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final courses = topCategory?.courses ?? const <home_models.Course>[];
    if (courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: CText(
          'Featured courses appear when new courses are added.',
          type: TextType.bodySmall,
          color: AppColors.gray500,
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final course = courses[index];
        final title = course.courseTitle ?? topCategory?.categoryName ?? '';
        final subtitle = course.categoryName ?? topCategory?.categoryName;

        final courseId = course.id?.toString();

        return InkWell(
          onTap: () {
            if (courseId == null || courseId.isEmpty) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListedCourseDetailsPage(courseId: courseId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Image
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomCachedNetworkImage(
                          imageUrl:
                              course.courseImageUrl ?? AppAssets.dummyNetImg,
                          size: const Size(80, 80),
                          fitStatus: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CText(
                          title,
                          type: TextType.bodyMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          CText(
                            subtitle,
                            type: TextType.bodySmall,
                            color: AppColors.gray600,
                          ),
                        ],
                        if (course.validityDays != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.gray500,
                              ),
                              const SizedBox(width: 4),
                              CText(
                                '${course.validityDays}d access',
                                type: TextType.bodySmall,
                                color: AppColors.gray600,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Save Icon
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
