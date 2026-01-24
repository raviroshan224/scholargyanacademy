import 'package:flutter/material.dart';
import '../../../../core/core.dart';

class ExploreTabContainer extends StatelessWidget {
  final String text;
  final bool isSelected;

  const ExploreTabContainer({
    super.key,
    required this.text,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding:
          const EdgeInsets.only(left: 24, top: 12.0, bottom: 12, right: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        color: isSelected ? AppColors.primary : AppColors.gray100,
      ),
      child: Tab(
        child: CText(
          text,
          type: TextType.bodyMedium,
          color: isSelected ? AppColors.white : AppColors.gray800,
        ),
      ),
    );
  }
}
