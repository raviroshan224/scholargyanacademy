import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/core/core.dart';
import 'package:scholarsgyanacademy/features/auth/view/pages/otp_page.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/confirm_email_view_model.dart';

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
