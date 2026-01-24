import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/core.dart';

class OnboardingWidget extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const OnboardingWidget({
    super.key,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: SvgPicture.asset(
              image,
            ),
          ),
          AppSpacing.verticalSpaceSmall,
          CText(title ?? '',type: TextType.headlineLarge,),
          AppSpacing.verticalSpaceSmall,
          CText(description,
              textAlign: TextAlign.center,
              type: TextType.headlineMedium,
              color: AppColors.text),
        ],
      ),
    );
  }
}
