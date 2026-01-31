import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../../dashboard/presentation/pages/dashboard.dart';

class ConfirmPage extends StatelessWidget {
  const ConfirmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: 'Payment Confirmation'),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [
                Image.asset(AppAssets.checkMarkIcon),
                AppSpacing.verticalSpaceLarge,
                CText(
                  'Congratulations!',
                  type: TextType.headlineLarge,
                ),
                AppSpacing.verticalSpaceMedium,
                CText(
                    'You have successfully made payment and enrolled the course.',
                    textAlign: TextAlign.center,
                    type: TextType.bodyMedium,
                    color: AppColors.gray600),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top:0, bottom:20, right:20,left:20),
        child: ReusableButton(text: "Go To Course", onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => Dashboard()));

        }),
      ),
    );
  }
}
