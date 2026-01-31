import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/services/simple_payment_service.dart';
import '../../../../core/widgets/buttons/reusable_buttons.dart';
import '../../../auth/view_model/providers/auth_providers.dart';

class EnrollWithEsewaButton extends ConsumerStatefulWidget {
  const EnrollWithEsewaButton({
    super.key,
    required this.courseId,
    required this.isEnrolled,
    this.promoCode,
    required this.enrollType,
  });

  final String courseId;
  final bool isEnrolled;
  final String? promoCode;
  final String enrollType;

  @override
  ConsumerState<EnrollWithEsewaButton> createState() =>
      _EnrollWithEsewaButtonState();
}

class _EnrollWithEsewaButtonState extends ConsumerState<EnrollWithEsewaButton> {
  bool _isProcessing = false;

  Future<void> _handleEnrollment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final paymentService = ref.read(simplePaymentServiceProvider);

      // Call payment initiate API
      final redirectUrl = await paymentService.initiatePayment(
        paymentType: 'course_enrollment',
        referenceId: widget.courseId,
        promoCode: widget.promoCode,
      );

      if (!mounted) return;

      if (redirectUrl == null) {
        // Show error if API call failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to initiate payment. Please try again.'),
            backgroundColor: AppColors.failure,
          ),
        );
        return;
      }

      // Open redirect URL in external browser
      final uri = Uri.parse(redirectUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open payment page. Please try again.'),
            backgroundColor: AppColors.failure,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.failure,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReusableButton(
      text: widget.isEnrolled ? 'Enrolled' : 'Enroll Now',
      isLoading: _isProcessing,
      backgroundColor: widget.isEnrolled
          ? AppColors.gray300
          : AppColors.secondary,
      onPressed: () async {
        final authState = ref.read(authNotifierProvider);
        final userId = authState.user?.id ?? '';

        final uri =
            Uri.parse(
              'https://scholargyan.onecloudlab.com/payment/checkout',
            ).replace(
              queryParameters: {
                'type': widget.enrollType,
                'referenceId': widget.courseId,
                'userId': userId,
              },
            );

        // Open redirect URL in external browser
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => PaymentWebViewPage(
        //       url: uri.toString(),
        //       title: 'Course Payment',
        //     ),
        //   ),
        // );
      },
    );
  }
}
