import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../models/homepage_models.dart' as home_models;
import '../../../courses/presentation/pages/enrolled_course_details_page.dart';

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
        final title = course.courseTitle ?? topCategory?.categoryName ?? '';
        final subtitle = course.categoryName ?? topCategory?.categoryName;

        final courseId = course.id?.toString();

        final enrollmentCost = course.enrollmentCost;
        final discountedPrice = course.discountedPrice;
        final hasOffer = course.hasOffer;

        final bool isFree = enrollmentCost == 0;
        final bool hasValidDiscount = hasOffer == true &&
            enrollmentCost != null &&
            discountedPrice != null &&
            enrollmentCost > discountedPrice;

        return InkWell(
          onTap: () {
            if (courseId == null || courseId.isEmpty) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EnrolledCourseDetailsPage(
                  courseId: courseId,
                ),
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
                  // Course Image with Badge
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
                      if (hasValidDiscount)
                        _buildBadge(
                          '${_calculateDiscount(enrollmentCost, discountedPrice)}% OFF',
                          const Color(0xFFEA4335),
                        ),
                      if (isFree)
                        _buildBadge('FREE', const Color(0xFF0F9D58)),
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
                        const SizedBox(height: 8),

                        // Price and validity row
                        Row(
                          children: [
                            _buildPrice(
                                isFree, hasValidDiscount, enrollmentCost, discountedPrice),
                            if (course.validityDays != null) ...[
                              const Spacer(),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  int _calculateDiscount(int? original, int? discounted) {
    if (original == null || discounted == null || original == 0) return 0;
    return (((original - discounted) / original) * 100).round();
  }

  Widget _buildPrice(
      bool isFree, bool hasDiscount, int? enrollmentCost, int? discountedPrice) {
    if (isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F9D58).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Free',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F9D58),
          ),
        ),
      );
    }

    if (hasDiscount) {
      return Row(
        children: [
          Text(
            'Rs ${NumberFormat('#,##,###').format(discountedPrice)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Rs ${NumberFormat('#,##,###').format(enrollmentCost)}',
            style: const TextStyle(
              fontSize: 11,
              decoration: TextDecoration.lineThrough,
              color: AppColors.gray500,
            ),
          ),
        ],
      );
    }

    if (enrollmentCost != null) {
      return Text(
        'Rs ${NumberFormat('#,##,###').format(enrollmentCost)}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
