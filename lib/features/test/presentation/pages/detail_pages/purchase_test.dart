import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/core.dart';

class PurchaseTest extends StatelessWidget {
  const PurchaseTest({super.key, required this.paymentPayload});

  final Map<String, dynamic> paymentPayload;

  @override
  Widget build(BuildContext context) {
    final amount = _parseAmount(paymentPayload);
    final currency = paymentPayload['currency']?.toString() ?? 'INR';
    final paymentUrl = _parseUrl(paymentPayload);
    final reference = paymentPayload['referenceId']?.toString() ??
        paymentPayload['reference']?.toString();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: 'Complete Payment'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CText('Amount Due',
                        type: TextType.bodyLarge, color: AppColors.black),
                    AppSpacing.verticalSpaceSmall,
                    CText(
                      amount != null
                          ? '$currency ${amount.toStringAsFixed(2)}'
                          : 'Refer to payment portal',
                      type: TextType.headlineMedium,
                      color: AppColors.primary,
                    ),
                    if (reference != null) ...[
                      AppSpacing.verticalSpaceMedium,
                      CText('Reference ID', type: TextType.bodyMedium),
                      CText(reference,
                          type: TextType.bodySmall, color: AppColors.gray700),
                    ],
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpaceLarge,
            const CText('Payment Details',
                type: TextType.bodyLarge, color: AppColors.black),
            AppSpacing.verticalSpaceSmall,
            _KeyValueList(entries: paymentPayload.entries.toList()),
            const Spacer(),
            ReusableButton(
              text: paymentUrl != null ? 'Continue to Payment' : 'Close',
              onPressed: paymentUrl != null
                  ? () => _launchPayment(context, paymentUrl)
                  : () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  double? _parseAmount(Map<String, dynamic> payload) {
    final value = payload['amount'] ?? payload['total'] ?? payload['price'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? _parseUrl(Map<String, dynamic> payload) {
    final url = payload['paymentUrl'] ?? payload['redirectUrl'];
    if (url is String && url.isNotEmpty) return url;
    return null;
  }

  Future<void> _launchPayment(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid payment link.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open payment link.')),
      );
    }
  }
}

class _KeyValueList extends StatelessWidget {
  const _KeyValueList({required this.entries});

  final List<MapEntry<String, dynamic>> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const CText(
        'No additional payment information provided.',
        type: TextType.bodySmall,
        color: AppColors.gray600,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CText(
                      entry.key,
                      type: TextType.bodySmall,
                      color: AppColors.gray600,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: CText(
                      _stringify(entry.value),
                      type: TextType.bodySmall,
                      color: AppColors.gray800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _stringify(dynamic value) {
    if (value == null) return '-';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is List) {
      return value.map(_stringify).join(', ');
    }
    if (value is Map) {
      return value.entries
          .map((e) => '${e.key}: ${_stringify(e.value)}')
          .join(', ');
    }
    return value.toString();
  }
}
