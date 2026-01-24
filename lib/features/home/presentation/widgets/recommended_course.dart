import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../courses/presentation/pages/enrolled_course_details_page.dart';
import 'home_course_card.dart';

typedef CourseCardTap = void Function(CourseCardData data);

class RecommendedCourse extends StatelessWidget {
  const RecommendedCourse(
      {super.key,
      required this.items,
      this.isLoading = false,
      this.onItemTap,
      this.emptyLabel,
      this.cardHeight = 219});

  final List<CourseCardData> items;
  final bool isLoading;
  final CourseCardTap? onItemTap;
  final String? emptyLabel;
  final double? cardHeight;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 28,
                color: AppColors.gray400,
              ),
              const SizedBox(height: 8),
              CText(
                emptyLabel ?? 'No courses available right now',
                type: TextType.bodySmall,
                color: AppColors.gray500,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
        height: cardHeight,
        child: CourseCard(items: items, onItemTap: onItemTap));
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  final List<CourseCardData> items;
  final CourseCardTap? onItemTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final item = items[index];

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (onItemTap != null) {
              onItemTap!(item);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnrolledCourseDetailsPage(
                    courseId: item.courseId!,
                  ),
                ),
              );
            }
          },
          child: SizedBox(
            width: 180,
            child: HomeCourseCard(
              title: item.title,
              subtitle: item.subtitle ?? 'Explore course',
              imagePath: item.imageUrl ?? AppAssets.errorImage,
              courseId: item.courseId,
              isSaved: item.isSaved,
              enrollmentCost: item.enrollmentCost,
              durationHours: item.durationHours,
              validityDays: item.validityDays,
            ),
          ),
        );
      },
    );
  }
}

class CourseCardData {
  CourseCardData({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.courseId,
    this.isSaved = false,
    this.enrollmentCost,
    this.durationHours,
    this.validityDays,
    this.categoryId,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? courseId;
  final bool isSaved;
  final int? enrollmentCost;
  final int? durationHours;
  final int? validityDays;
  final String? categoryId;
}
