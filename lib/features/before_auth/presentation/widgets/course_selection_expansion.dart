import 'package:flutter/material.dart';
import 'package:scholarsgyanacademy/features/profile/data/models/favorite_category_model.dart';

import '../../../../core/core.dart';

class CourseSelectionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? svgPath;
  final List<ChildCategoryModel> childCategories;
  final Function(String) onTap;
  final bool initiallyExpanded;

  const CourseSelectionItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.svgPath,
    required this.childCategories,
    required this.onTap,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Row(
          children: [
            if (svgPath == null)
              SizedBox(
                width: 50,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    "assets/pictures/Default_image.png",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (svgPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  svgPath!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            AppSpacing.horizontalSpaceMedium,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CText(title, type: TextType.bodyMedium, color: AppColors.black),
                CText(
                  subtitle,
                  type: TextType.bodySmall,
                  color: AppColors.gray600,
                ),
              ],
            ),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 0,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                runAlignment: WrapAlignment.start,
                children: childCategories.map((child) {
                  return ChoiceChip(
                    label: Text(child.categoryName),
                    selected: child.isSelected,
                    onSelected: (isSelected) {
                      onTap(child.id);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
