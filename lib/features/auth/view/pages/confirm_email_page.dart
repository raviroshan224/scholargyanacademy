import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_string.dart';
import '../../../../core/utils/ui_helper/app_spacing.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/buttons/reusable_buttons.dart';
import '../../../../core/widgets/form/cus_text_field.dart';
import '../../../../core/widgets/form/field_validators.dart';
import '../../../../core/widgets/text/custom_text.dart';
import '../../view_model/confirm_email_view_model.dart';
import 'otp_page.dart';

class ConfirmEmailPage extends ConsumerWidget {
  const ConfirmEmailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmEmailViewModel = ref.watch(confirmEmailViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            CText(
              AppStrings.enterEmailAddress,
              type: TextType.headlineLarge,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpaceMedium,
            CText(
              AppStrings.enterEmailAddressForConfirmation,
              textAlign: TextAlign.start,
              type: TextType.bodyMedium,
            ),
            AppSpacing.verticalSpaceLarge,
            Form(
              key: confirmEmailViewModel.formKey,
              child: Column(
                children: [
                  CustTextField(
                    hintText: AppStrings.email,
                    hintColor: AppColors.gray400,
                    prefixIcon: const Icon(Icons.email),
                    controller: confirmEmailViewModel.emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: FieldValidators.validateEmail,
                  ),
                  if (confirmEmailViewModel.getFieldErrorText('email') != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          confirmEmailViewModel.getFieldErrorText('email')!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  AppSpacing.verticalSpaceLarge,
                  SizedBox(
                    width: double.infinity,
                    child: ReusableButton(
                      text: 'Next',
                      isLoading: confirmEmailViewModel.isLoading,
                      onPressed: confirmEmailViewModel.isLoading
                          ? null
                          : () async {
                              final success = await confirmEmailViewModel
                                  .submitConfirmEmail(context);
                              if (success && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OtpPage(
                                      email: confirmEmailViewModel
                                          .emailController
                                          .text,
                                    ),
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalSpaceLarge,
          ],
        ),
      ),
    );
  }
}
