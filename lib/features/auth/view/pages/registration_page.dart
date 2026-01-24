import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:scholarsgyanacademy/core/core.dart';
import 'package:scholarsgyanacademy/features/auth/view/pages/login_page.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/auth_state.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/register_view_model.dart';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key});

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerViewModelProvider).listenToAuthChanges(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final registerViewModel = ref.watch(registerViewModelProvider);
    final authState = ref.watch(authNotifierProvider);
    final isPasswordVisible = ref.watch(isRegisterPasswordVisibleProvider);
    final isConfirmPasswordVisible = ref.watch(
      isRegisterConfirmPasswordVisibleProvider,
    );
    final apiErrors = authState.status == AuthStatus.error
        ? authState.fieldErrors ?? {}
        : const <String, List<String>>{};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            AppSpacing.verticalSpaceMedium,
            CText(
              textAlign: TextAlign.center,
              AppStrings.createAccount,
              type: TextType.headlineLarge,
            ),
            AppSpacing.verticalSpaceLarge,
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustTextField(
                    hintText: AppStrings.fullName,
                    prefixIcon: const Icon(Icons.person),
                    controller: registerViewModel.nameController,
                    validator: FieldValidators.validateFullName,
                    errorText: apiErrors['fullName']?.first,
                  ),
                  AppSpacing.verticalSpaceLarge,
                  CustTextField(
                    hintText: AppStrings.email,
                    prefixIcon: const Icon(Icons.email),
                    controller: registerViewModel.emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: FieldValidators.validateEmail,
                    errorText: apiErrors['email']?.first,
                  ),
                  AppSpacing.verticalSpaceLarge,
                  CustTextField(
                    hintText: AppStrings.contactNumber,
                    prefixIcon: const Icon(Icons.phone),
                    controller: registerViewModel.phoneController,
                    keyboardType: TextInputType.phone,
                    validator: FieldValidators.validateContactNumber,
                    errorText: apiErrors['mobileNumber']?.first,
                  ),
                  AppSpacing.verticalSpaceLarge,
                  CustTextField(
                    hintText: AppStrings.password,
                    prefixIcon: const Icon(Icons.lock),
                    controller: registerViewModel.passwordController,
                    obscureText: !isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        ref
                            .read(isRegisterPasswordVisibleProvider.notifier)
                            .update((state) => !state);
                      },
                    ),
                    validator: FieldValidators.validatePassword,
                    errorText: apiErrors['password']?.first,
                  ),
                  AppSpacing.verticalSpaceLarge,
                  CustTextField(
                    hintText: AppStrings.confirmPassword,
                    prefixIcon: const Icon(Icons.lock),
                    controller: registerViewModel.confirmPasswordController,
                    obscureText: !isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        ref
                            .read(
                              isRegisterConfirmPasswordVisibleProvider.notifier,
                            )
                            .update((state) => !state);
                      },
                    ),
                    validator: (value) =>
                        FieldValidators.validateConfirmPassword(
                          value,
                          registerViewModel.passwordController.text,
                        ),
                    errorText: apiErrors['confirmPassword']?.first,
                  ),
                  AppSpacing.verticalSpaceLarge,
                  SizedBox(
                    width: double.infinity,
                    child: ReusableButton(
                      text: AppStrings.signUp,
                      isLoading: authState.status == AuthStatus.loading,
                      onPressed: authState.status == AuthStatus.loading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                registerViewModel.submitRegistration(context);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalSpaceMedium,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CText(AppStrings.alreadyHaveAccount, type: TextType.bodyLarge),
                AppSpacing.horizontalSpaceAverage,
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: CText(
                    AppStrings.signIn,
                    color: AppColors.secondary,
                    type: TextType.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final isRegisterPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final isRegisterConfirmPasswordVisibleProvider = StateProvider<bool>(
  (ref) => false,
);
