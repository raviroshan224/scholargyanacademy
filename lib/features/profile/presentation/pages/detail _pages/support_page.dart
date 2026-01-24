import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/core.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Help and Support'
      ),
      body: Padding(
        padding: EdgeInsets.only(right: 16.0, left: 16),
        child: Column(
          children: [
            AppSpacing.verticalSpaceMedium,
            CText(
              'Need a guidance?',
                 type:TextType.headlineMedium,
            ),
            AppSpacing.verticalSpaceMedium,
            CText(
              'Uma proin condimentum nunc commodo eget. Condimentum quam ultrices at.',
              type: TextType.bodyMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpaceLarge,
            ReusableButton(
              backgroundColor: AppColors.primary,
              text: " Chat on WhatsApp",
              btnIcon: SvgPicture.asset(AppAssets.whatsappIcon),
              onPressed: () {},
            ),
            AppSpacing.verticalSpaceMedium,
            ReusableButton(
              borderColor: AppColors.gray800,
              text: " Call Now",
              textColor: AppColors.black,
              backgroundColor: AppColors.white,
              btnIcon: SvgPicture.asset(AppAssets.callIcon),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
