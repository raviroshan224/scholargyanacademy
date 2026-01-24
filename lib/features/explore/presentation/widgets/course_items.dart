import 'package:flutter/material.dart';

import '../../../../core/core.dart';

class CourseItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;

  const CourseItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCachedNetworkImage(
              imageUrl: AppAssets.dummyNetImg,
              size: Size(180, 180),
            ),
            AppSpacing.verticalSpaceSmall,
            CText(
              title,
              maxLines: 2,
              type: TextType.labelLarge,
            ),
            CText(
              subtitle,
              maxLines: 2,
              type: TextType.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
