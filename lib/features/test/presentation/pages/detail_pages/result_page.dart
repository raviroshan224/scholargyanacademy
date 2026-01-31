import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../view_model/test_session_view_model.dart';
import '../../../view_model/test_outcome_view_model.dart';
import '../../widgets/details_card.dart';
import '../../widgets/process_circle.dart';
import '../../widgets/remarks_section.dart';
import 'solution_page.dart';

class ResultPage extends ConsumerStatefulWidget {
  const ResultPage({
    super.key,
    this.showDoneButton = true,
  });

  final bool showDoneButton;

  @override
  ConsumerState<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<ResultPage> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureData();
    });
  }

  void _ensureData() {
    if (_requested) return;
    final sessionId = ref.read(testSessionViewModelProvider).sessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      ref
          .read(testResultControllerProvider.notifier)
          .fetch(sessionId, force: true);
    }
    _requested = true;
  }

  Future<void> _openSolutions() async {
    final sessionId = ref.read(testSessionViewModelProvider).sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }
    await ref
        .read(testSolutionsControllerProvider.notifier)
        .fetch(sessionId, force: true);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SolutionsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(testSessionViewModelProvider);
    final resultState = ref.watch(testResultControllerProvider);
    final solutionsState = ref.watch(testSolutionsControllerProvider);
    final evaluation = resultState.result;
    final summary = evaluation?.summary;
    final session = sessionState.session;
    final examTitle = session?.examTitle ?? 'Test Evaluation';
    final bool hasEvaluation = evaluation != null;
    final totalQuestions =
        evaluation?.totalQuestions ?? summary?.totalQuestions ?? 0;
    final skipped = evaluation?.skippedQuestions ?? summary?.skipped ?? 0;
    final correct = evaluation?.correctAnswers ?? summary?.correct ?? 0;
    final incorrect = evaluation?.wrongAnswers ?? summary?.incorrect ?? 0;
    final displayIncorrect = incorrect < 0 ? 0 : incorrect;
    var attempted = totalQuestions - skipped;
    if (attempted < 0) {
      attempted = 0;
    }
    final percentage = evaluation?.scorePercentage ?? summary?.percentage ?? 0;
    // final remarks = evaluation?.feedback ??
    //     'Your test has been submitted successfully. Review the details below.';

    if (resultState.isLoading && !hasEvaluation) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!hasEvaluation) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: CustomAppBar(title: examTitle),
        body: Center(
          child: CText(
            resultState.error?.message ??
                'Result is not available yet. Please try again shortly.',
            type: TextType.bodyMedium,
            color: AppColors.gray700,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: examTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressCircle(percentage: percentage.round()),
                AppSpacing.horizontalSpaceLarge,
                Expanded(
                  child: DetailsCard(
                    totalQuestions: totalQuestions,
                    attempted: attempted,
                    correct: correct,
                    incorrect: displayIncorrect,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMedium,
            ReusableButton(
              text: 'View Solutions',
              isLoading: solutionsState.isLoading,
              onPressed:
                  solutionsState.items.isEmpty && solutionsState.isLoading
                      ? null
                      : () {
                          _openSolutions();
                        },
            ),
            AppSpacing.verticalSpaceLarge,
            // RemarksSection(remarks: remarks),
            if (widget.showDoneButton) ...[
              AppSpacing.verticalSpaceLarge,
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CText('Next Steps',
                          type: TextType.headlineMedium,
                          color: AppColors.black),
                      AppSpacing.verticalSpaceAverage,
                      const CText(
                        'Review your answers and revisit weak topics to improve your score.',
                        type: TextType.bodySmall,
                      ),
                      AppSpacing.verticalSpaceLarge,
                      ReusableButton(
                        text: 'Done',
                        backgroundColor: AppColors.primary,
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
