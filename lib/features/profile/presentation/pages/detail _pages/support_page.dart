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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppSpacing.verticalSpaceLarge,
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 72,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.verticalSpaceLarge,
            const CText(
              'How can we help you?',
                 type:TextType.headlineSmall,
                 fontWeight: FontWeight.bold,
                 color: AppColors.black,
            ),
            AppSpacing.verticalSpaceMedium,
            const CText(
              'Our support team is here to assist you with any questions regarding our courses, tests, or your account. Reach out to us for complete guidance and support.',
              type: TextType.bodyMedium,
              color: AppColors.gray800,
              textAlign: TextAlign.center,
              height: 1.5,
            ),
            AppSpacing.verticalSpaceLarge,
            AppSpacing.verticalSpaceAverage,
            ReusableButton(
              backgroundColor: const Color(0xFF25D366), // WhatsApp Green
              text: " Chat on WhatsApp",
              btnIcon: SvgPicture.asset(
                AppAssets.whatsappIcon,
                colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
              ),
              onPressed: () {},
            ),
            AppSpacing.verticalSpaceAverage,
            ReusableButton(
              borderColor: AppColors.gray200,
              text: " Call Now",
              textColor: AppColors.black,
              backgroundColor: AppColors.white,
              btnIcon: const Icon(
                Icons.phone_outlined,
                color: AppColors.black,
                size: 20,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
