import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/iap/iap_provider.dart';
import '../../../../core/iap/paywall_page.dart';
import '../../../../core/widgets/text/custom_text.dart';
import '../../../auth/view_model/providers/auth_providers.dart';
import '../../model/course_models.dart';
import '../widgets/enroll_with_esewa_button.dart';

class PackagePaymentPage extends ConsumerStatefulWidget {
  final CourseModel course;
  final String enrollType;
  final String courseId;

  const PackagePaymentPage({
    super.key,
    required this.course,
    this.enrollType = 'course_enrollment',
    required this.courseId,
  });

  @override
  ConsumerState<PackagePaymentPage> createState() => _PackagePaymentPageState();
}

class _PackagePaymentPageState extends ConsumerState<PackagePaymentPage> {
  bool _isProcessing = false;

  void _handleEsewaEnrollment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authState = ref.read(authNotifierProvider);
      final userId = authState.user?.id ?? '';

      final uri =
          Uri.parse(
            'https://scholargyan.onecloudlab.com/payment/checkout',
          ).replace(
            queryParameters: {
              'type': widget.enrollType,
              'referenceId': widget.course.id,
              'userId': userId,
            },
          );

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
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

  void _handleIapEnrollment() {
    final iapController = ref.read(iapControllerProvider);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaywallPage(
          productId: widget.course.id,
          iapController: iapController,
        ),
      ),
    ).then((purchased) {
      if (purchased == true) {
        Navigator.pop(context, true); // Return true to refresh details
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final total =
        (widget.course.hasOffer == true &&
            widget.course.discountedPrice != null &&
            widget.course.discountedPrice! > 0)
        ? widget.course.discountedPrice!.toDouble()
        : widget.course.enrollmentCost?.toDouble() ?? 0.0;

    final taxableAmount = total / 1.13;
    final vatAmount = total - taxableAmount;
    final formatter = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const CText(
          'Package Payment',
          type: TextType.headlineSmall,
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CText(
                    'Order Summary',
                    type: TextType.bodyLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CText(
                          widget.course.courseTitle,
                          type: TextType.bodyMedium,
                          color: Colors.black54,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CText(
                        'Rs.${formatter.format(total)}',
                        type: TextType.bodyMedium,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CText(
                        'Taxable amount',
                        type: TextType.bodyMedium,
                        color: Colors.black54,
                      ),
                      CText(
                        'Rs.${formatter.format(taxableAmount)}',
                        type: TextType.bodyMedium,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CText(
                        'Vat amount (13.0%)',
                        type: TextType.bodyMedium,
                        color: Colors.black54,
                      ),
                      CText(
                        'Rs.${formatter.format(vatAmount)}',
                        type: TextType.bodyMedium,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(thickness: 1.5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CText(
                        'Total Amount',
                        type: TextType.bodyLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      CText(
                        'Rs.${formatter.format(total)}',
                        type: TextType.bodyLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Promo Code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: const [
                  Icon(Icons.local_offer, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  CText(
                    'Use Promo Code',
                    type: TextType.bodyMedium,
                    color: Colors.black54,
                  ),
                  Spacer(),
                  Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select Load Option
            const CText(
              'Select Load Option',
              type: TextType.bodyLarge,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            const SizedBox(height: 12),

            if (Platform.isIOS) ...[
              // iOS Flow: In-App Purchases
              InkWell(
                onTap: _handleIapEnrollment,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.apple, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      CText(
                        'Pay with Apple',
                        type: TextType.bodyLarge,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Android Flow: eSewa
            SizedBox(height: 20),
            EnrollWithEsewaButton(
              courseId: widget.courseId,
              isEnrolled: false,
              promoCode: null,
              enrollType: 'course_enrollment',
            ),

            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.only(top: 24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String name,
    String asset,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: CText(
              name,
              type: TextType.bodyLarge,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
