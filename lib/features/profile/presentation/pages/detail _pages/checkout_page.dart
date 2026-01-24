import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../profile.dart';
import '../../../../auth/view_model/providers/auth_providers.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.user?.fullName ?? 'Course';

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Checkout',
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/pictures/courseselection.png',
                  width: 100,
                ),
                AppSpacing.horizontalSpaceMedium,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CText(
                      userName,
                      type: TextType.bodyMedium,
                      color: AppColors.black,
                    ),
                    AppSpacing.verticalSpaceSmall,
                    CText('Rs. 4000',
                        color: AppColors.secondary, type: TextType.bodySmall),
                    AppSpacing.verticalSpaceSmall,
                    CText('3 Courses',
                        type: TextType.bodySmall, color: AppColors.gray600),
                  ],
                ),
              ],
            ),
            Divider(
              thickness: 1,
            ),
            AppSpacing.verticalSpaceLarge,
            CText('Select Payment Option',
                type: TextType.bodyLarge, color: AppColors.black),
            AppSpacing.verticalSpaceMedium,
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.gray300, // Border color
                      // Border width
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/pictures/image17.png',
                      height: 40.0,
                      width: 100,
                    ),
                  ),
                ),
                AppSpacing.horizontalSpaceMedium,
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.gray300, // Border color
                      // Border width
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/pictures/image18.png',
                      height: 40.0,
                      width: 100,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceLarge,
            Expanded(
              child: PriceSectionWidget(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 20, right: 20, left: 20),
        child: ReusableButton(
            text: "Confirm",
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ConfirmPage()));
            }),
      ),
    );
  }
}
