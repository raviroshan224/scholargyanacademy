import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../courses/view_model/course_view_model.dart';

class HomeCourseCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final String? courseId;
  final bool isSaved;
  final int? enrollmentCost;
  final int? durationHours;
  final int? validityDays;
  final bool? isGrid;

  const HomeCourseCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.imagePath,
      this.courseId,
      this.isSaved = false,
      this.enrollmentCost,
      this.durationHours,
      this.validityDays,
      this.isGrid = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final imageHeight = isGrid == false ? 150.0 : 160.0;

      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image with Bookmark
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomCachedNetworkImage(
                      imageUrl: imagePath,
                      fitStatus: BoxFit.cover,
                      errorImage: AppAssets.errorImage,
                    ),
                    // Bookmark Icon
                    if (courseId != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () async {
                            final current = isSaved;
                            final result = await ref
                                .read(coursesViewModelProvider.notifier)
                                .toggleSave(courseId!, currentlySaved: current);

                            result.fold((l) {
                              AppMethods.showCustomSnackBar(
                                  context: context,
                                  message: l.message,
                                  isError: true);
                            }, (isNowSaved) {
                              AppMethods.showCustomSnackBar(
                                  context: context,
                                  message: isNowSaved ? 'Saved' : 'Removed');
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_outline,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  CText(
                    title,
                    type: TextType.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Duration + Cost Row
                  Row(
                    children: [
                      if (durationHours != null && durationHours! > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.gray600,
                            ),
                            const SizedBox(width: 6),
                            CText(
                              '${durationHours}h',
                              type: TextType.bodySmall,
                              color: AppColors.gray600,
                            ),
                          ],
                        ),
                      // if (enrollmentCost != null) ...[
                      //   if (durationHours != null && durationHours! > 0)
                      //     const SizedBox(width: 12),
                      //   CText(
                      //     'Rs ${NumberFormat.compact().format(enrollmentCost)}',
                      //     type: TextType.bodySmall,
                      //     color: AppColors.secondary,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
