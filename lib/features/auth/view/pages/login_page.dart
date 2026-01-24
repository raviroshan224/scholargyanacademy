import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:scholarsgyanacademy/core/core.dart';
import 'package:scholarsgyanacademy/features/auth/view/pages/confirm_email_page.dart';
import 'package:scholarsgyanacademy/features/auth/view/pages/registration_page.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/auth_state.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/login_view_model.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';

final isLoginPasswordVisibleProvider = StateProvider<bool>((ref) => false);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loginViewModelProvider).listenToAuthChanges(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = ref.watch(loginViewModelProvider);
    final isPasswordVisible = ref.watch(isLoginPasswordVisibleProvider);
    final authState = ref.watch(authNotifierProvider);
    final apiErrors = authState.status == AuthStatus.error
        ? authState.fieldErrors ?? {}
        : const <String, List<String>>{};

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              AppSpacing.verticalSpaceLarge,
              Image.asset(
                AppAssets.loginBg,
                height: AppSpacing.screenHeight(context) * 0.30,
              ),
              AppSpacing.verticalSpaceMedium,
              CText(
                textAlign: TextAlign.center,
                AppStrings.loginToAccount,
                type: TextType.headlineLarge,
              ),
              AppSpacing.verticalSpaceLarge,
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustTextField(
                      hintText: AppStrings.email,
                      prefixIcon: const Icon(Icons.email),
                      controller: loginViewModel.userNameController,
                      validator: FieldValidators.validateEmail,
                      errorText: apiErrors['email']?.first,
                    ),
                    AppSpacing.verticalSpaceLarge,
                    CustTextField(
                      hintText: AppStrings.password,
                      prefixIcon: const Icon(Icons.lock),
                      controller: loginViewModel.passwordController,
                      obscureText: !isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          ref
                              .read(isLoginPasswordVisibleProvider.notifier)
                              .update((state) => !state);
                        },
                      ),
                      validator: FieldValidators.validatePassword,
                      errorText: apiErrors['password']?.first,
                    ),
                    AppSpacing.verticalSpaceAverage,
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConfirmEmailPage(),
                            ),
                          );
                        },
                        child: CText(
                          AppStrings.forgotPassword,
                          color: AppColors.secondary,
                          type: TextType.bodySmall,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    AppSpacing.verticalSpaceLarge,
                    SizedBox(
                      width: double.infinity,
                      child: ReusableButton(
                        text: AppStrings.signIn,
                        isLoading: loginViewModel.isLoading,
                        onPressed: loginViewModel.isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  loginViewModel.handleLogin(context);
                                }
                              },
                      ),
                    ),
                    AppSpacing.verticalSpaceMedium,
                  ],
                ),
              ),
              AppSpacing.verticalSpaceMedium,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CText(AppStrings.noAccount, type: TextType.bodyLarge),
                  AppSpacing.horizontalSpaceAverage,
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistrationPage(),
                        ),
                      );
                    },
                    child: CText(
                      AppStrings.signUp,
                      color: AppColors.secondary,
                      type: TextType.bodyLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
