import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/core/services/simple_payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/core.dart';
import '../../../../auth/view_model/providers/auth_providers.dart';
import '../../../models/mock_test_models.dart';
import '../../../view_model/mock_test_view_model.dart';
import '../../../view_model/test_session_view_model.dart';
import 'quiz_page.dart';

class TestDetailsPage extends ConsumerStatefulWidget {
  const TestDetailsPage({super.key, required this.initialTest});

  final MockTest initialTest;

  @override
  ConsumerState<TestDetailsPage> createState() => _TestDetailsPageState();
}

class _TestDetailsPageState extends ConsumerState<TestDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(mockTestViewModelProvider.notifier)
          .loadMockTestDetail(widget.initialTest.id);
    });
  }

  @override
  void dispose() {
    ref.read(mockTestViewModelProvider.notifier).clearDetail();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mockTestViewModelProvider);
    final notifier = ref.read(mockTestViewModelProvider.notifier);
    final sessionNotifier = ref.read(testSessionViewModelProvider.notifier);

    final isLoading =
        state.loadingDetail && (state.selectedTestId == widget.initialTest.id);
    final detail = state.selectedTestId == widget.initialTest.id
        ? state.selectedTest
        : null;
    final mockTest = detail ?? widget.initialTest;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: mockTest.title ?? 'Mock Test Details',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Payment and test access controls
                if (!mockTest.isFree && !mockTest.isPurchased) ...[
                  _BuyTestButton(testId: mockTest.id),
                ] else if (mockTest.canTakeTest) ...[
                  ReusableButton(
                    text: 'Start Test',
                    isLoading: ref
                        .watch(testSessionViewModelProvider)
                        .isStarting,
                    onPressed: () async {
                      await _handleStartTest(
                        context: context,
                        test: mockTest,
                        sessionNotifier: sessionNotifier,
                      );
                    },
                  ),
                ] else ...[
                  // Blocked state from backend
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: CText(
                      'Unavailable',
                      type: TextType.bodyMedium,
                      color: AppColors.failure,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderSection(mockTest: mockTest),
                  AppSpacing.verticalSpaceLarge,
                  if (mockTest.description?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Html(
                        data: mockTest.description,
                        style: {
                          'body': Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize.medium,
                            color: AppColors.gray700,
                          ),
                        },
                      ),
                    ),
                  AppSpacing.verticalSpaceLarge,
                  _InstructionSection(instructions: mockTest.instructions),
                  AppSpacing.verticalSpaceLarge,
                  _SubjectDistributionSection(
                    subjectDistribution: mockTest.subjectDistribution,
                  ),
                  AppSpacing.verticalSpaceLarge,
                  _ExtraMetadata(extra: mockTest.extra),
                  if (state.detailError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.failure,
                            size: 16,
                          ),
                          AppSpacing.horizontalSpaceSmall,
                          Expanded(
                            child: CText(
                              state.detailError!.message,
                              type: TextType.bodySmall,
                              color: AppColors.failure,
                            ),
                          ),
                          TextButton(
                            onPressed: () => notifier.loadMockTestDetail(
                              widget.initialTest.id,
                            ),
                            child: const CText('Retry'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  /// MANDATORY FIX #4: Start test (no auto-start after payment)
  Future<void> _handleStartTest({
    required BuildContext context,
    required MockTest test,
    required TestSessionViewModel sessionNotifier,
  }) async {
    final scaffold = ScaffoldMessenger.of(context);
    final session = await sessionNotifier.startTest(test.id);
    if (!mounted) return;

    if (session == null) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('Unable to start test. Please retry.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPage(sessionId: session.sessionId),
      ),
    );
  }
}

/// Buy Test Button - Simple payment flow
class _BuyTestButton extends ConsumerStatefulWidget {
  const _BuyTestButton({required this.testId});

  final String testId;

  @override
  ConsumerState<_BuyTestButton> createState() => _BuyTestButtonState();
}

class _BuyTestButtonState extends ConsumerState<_BuyTestButton> {
  bool _isProcessing = false;

  Future<void> _handleBuyTest() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final paymentService = ref.read(simplePaymentServiceProvider);

      // Call payment initiate API
      final redirectUrl = await paymentService.initiatePayment(
        paymentType: 'test_purchase',
        referenceId: widget.testId,
        promoCode: null,
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
      text: 'Buy Test',
      isLoading: _isProcessing,
      onPressed: () async {
        final authState = ref.read(authNotifierProvider);
        final userId = authState.user?.id ?? '';

        final uri =
            Uri.parse(
              'https://scholargyan.onecloudlab.com/payment/checkout',
            ).replace(
              queryParameters: {
                'type': 'test_purchase',
                'referenceId': widget.testId,
                'userId': userId,
              },
            );
        debugger(message: uri.toString());
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => PaymentWebViewPage(
        //       url: uri.toString(),
        //       title: 'Test Payment',
        //     ),
        //   ),
        // );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.mockTest});

  final MockTest mockTest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        CText(
          mockTest.title ?? 'Mock Test',
          type: TextType.headlineMedium,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        AppSpacing.verticalSpaceMedium,

        // Compact info row with icons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (mockTest.numberOfQuestions != null) ...[
                    Expanded(
                      child: _IconInfo(
                        icon: Icons.quiz_outlined,
                        label: 'Questions',
                        value: '${mockTest.numberOfQuestions}',
                      ),
                    ),
                  ],
                  if (mockTest.durationMinutes != null) ...[
                    Expanded(
                      child: _IconInfo(
                        icon: Icons.access_time,
                        label: 'Duration',
                        value: '${mockTest.durationMinutes} min',
                      ),
                    ),
                  ],
                ],
              ),
              if (mockTest.passingPercentage != null ||
                  mockTest.remainingAttempts != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (mockTest.passingPercentage != null) ...[
                      Expanded(
                        child: _IconInfo(
                          icon: Icons.check_circle_outline,
                          label: 'Pass Mark',
                          value:
                              '${mockTest.passingPercentage?.toStringAsFixed(0)}%',
                        ),
                      ),
                    ],
                    if (mockTest.remainingAttempts != null) ...[
                      Expanded(
                        child: _IconInfo(
                          icon: Icons.repeat,
                          label: 'Attempts Left',
                          value: '${mockTest.remainingAttempts}',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// New compact icon-based info widget
class _IconInfo extends StatelessWidget {
  const _IconInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CText(label, type: TextType.bodySmall, color: AppColors.gray600),
            CText(
              value,
              type: TextType.bodyMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ],
        ),
      ],
    );
  }
}

class _InstructionSection extends StatelessWidget {
  const _InstructionSection({required this.instructions});

  final List<String> instructions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CText(
            'Instructions',
            type: TextType.titleMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          const SizedBox(height: 12),
          if (instructions.isEmpty)
            const CText(
              'No special instructions for this test.',
              type: TextType.bodyMedium,
              color: AppColors.gray500,
            )
          else
            ...instructions.map(
              (instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CText(
                      '•  ',
                      type: TextType.bodyMedium,
                      color: AppColors.primary,
                    ),
                    Expanded(
                      child: CText(
                        instruction,
                        type: TextType.bodyMedium,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubjectDistributionSection extends StatelessWidget {
  const _SubjectDistributionSection({required this.subjectDistribution});

  final List<Map<String, dynamic>> subjectDistribution;

  @override
  Widget build(BuildContext context) {
    if (subjectDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'Subject Distribution',
      child: Column(
        children: subjectDistribution
            .map(
              (entry) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: CText(
                  entry['subjectName']?.toString() ??
                      entry['subject']?.toString() ??
                      'Subject',
                  type: TextType.bodyMedium,
                ),
                trailing: CText(
                  entry['questionCount']?.toString() ??
                      entry['questions']?.toString() ??
                      entry['value']?.toString() ??
                      '-',
                  type: TextType.bodySmall,
                  color: AppColors.gray700,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ExtraMetadata extends StatelessWidget {
  const _ExtraMetadata({required this.extra});

  final Map<String, dynamic>? extra;

  @override
  Widget build(BuildContext context) {
    if (extra == null || extra!.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = extra!.entries.toList();
    return _SectionCard(
      title: 'Additional Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CText(
                        entry.key,
                        type: TextType.bodySmall,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CText(
                        entry.value.toString(),
                        type: TextType.bodySmall,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CText(title, type: TextType.bodyLarge, color: AppColors.black),
            AppSpacing.verticalSpaceMedium,
            child,
          ],
        ),
      ),
    );
  }
}
