import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../models/homepage_models.dart' as home_models;

class GrabTheDealList extends StatelessWidget {
  const GrabTheDealList({
    super.key,
    this.topCategory,
    this.isLoading = false,
  });

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
          'Grab deals appear when top categories add new offers.',
          type: TextType.bodySmall,
          color: AppColors.gray500,
        ),
      );
    }

    final currencyFormatter = NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: 'Rs. ',
    );

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final course = courses[index];
        final priceText = course.enrollmentCost != null
            ? currencyFormatter.format(course.enrollmentCost)
            : 'Free';
        final title = course.courseTitle ?? topCategory?.categoryName ?? '';
        final subtitle = course.categoryName ?? topCategory?.categoryName;

        return Container(
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomCachedNetworkImage(
                    imageUrl: course.courseImageUrl ?? AppAssets.dummyNetImg,
                    size: Size(80, 80),
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
                      const SizedBox(height: 8),

                      // Price and validity row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CText(
                              priceText,
                              type: TextType.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                          if (course.validityDays != null) ...[
                            const SizedBox(width: 8),
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
                        ],
                      ),
                    ],
                  ),
                ),

                // Save Icon
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark_outline,
                    size: 18,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
