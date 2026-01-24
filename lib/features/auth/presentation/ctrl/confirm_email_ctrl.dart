// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
// import 'package:olp/features/auth/view_model/providers/auth_providers.dart';

// import '../../../../core/core.dart';
// import '../pages/otp_page.dart';

// final confirmEmailLoadingProvider = StateProvider<bool>((Ref ref) => false);

// final confirmEmailViewModelProvider = Provider.autoDispose<ConfirmEmailCtrl>((Ref ref) {
//   final ctrl = ConfirmEmailCtrl(ref);
//   ref.onDispose(() {
//     ctrl.dispose();
//   });
//   return ctrl;
// });

// class ConfirmEmailCtrl {
//   final Ref ref;

//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();
//   final TextEditingController emailController = TextEditingController();
//   final Map<String, String?> _fieldErrors = {};

//   ConfirmEmailCtrl(this.ref);

//   bool get isLoading => ref.read(confirmEmailLoadingProvider);

//   String? getFieldErrorText(String key) => _fieldErrors[key];

//   Future<bool> submitConfirmEmail(BuildContext context) async {
//     _fieldErrors.clear();
//     final email = emailController.text.trim();

//     if (email.isEmpty) {
//       AppMethods.showCustomSnackBar(
//         context: context,
//         message: 'Please enter an email',
//         isError: true,
//       );
//       return false;
//     }

//     ref.read(confirmEmailLoadingProvider.notifier).state = true;

//     try {
//       final authService = ref.read(authServiceProvider);
//       final res = await authService.forgotPassword(email);
//       res.fold((failure) {
//         final msg = failure.message;
//         // Try to parse field errors from JSON message
//         try {
//           final parsed = jsonDecode(msg);
//           if (parsed is Map<String, dynamic>) {
//             parsed.forEach((k, v) {
//               _fieldErrors[k] = v?.toString();
//             });
//           }
//         } catch (_) {
//           // not JSON, show plain message
//         }

//         AppMethods.showCustomSnackBar(
//           context: context,
//           message: msg,
//           isError: true,
//         );
//       }, (r) async {
//         // Success — navigate to OTP page for this email
//         AppMethods.showCustomSnackBar(
//           context: context,
//           message: 'OTP sent to your email',
//         );
//         if (context.mounted) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => OtpPage(email: email)),
//           );
//         }
//       });

//       return true;
//     } catch (e) {
//       AppMethods.showCustomSnackBar(
//         context: context,
//         message: 'Failed to request OTP. Please try again.',
//         isError: true,
//       );
//       return false;
//     } finally {
//       ref.read(confirmEmailLoadingProvider.notifier).state = false;
//     }
//   }

//   void dispose() {
//     emailController.dispose();
//   }
// }
