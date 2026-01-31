import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../models/test_session_models.dart';
import '../../../view_model/test_session_view_model.dart';
import '../../widgets/option_list.dart';
import '../../widgets/submit_dialog.dart';
import 'result_page.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({
    super.key,
    required this.sessionId,
    this.readOnly = false,
  });

  final String sessionId;
  final bool readOnly;

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureSessionLoaded();
    });
  }

  void _ensureSessionLoaded() {
    if (_initialised) {
      return;
    }
    final state = ref.read(testSessionViewModelProvider);
    final session = state.session;
    final hasSession = session != null &&
        session.sessionId == widget.sessionId &&
        session.questions.isNotEmpty;
    if (!hasSession) {
      ref
          .read(testSessionViewModelProvider.notifier)
          .loadSession(widget.sessionId);
    }
    _initialised = true;
  }

  Future<void> _handleOptionSelected(TestQuestionOption option) async {
    if (widget.readOnly) {
      return;
    }
    final state = ref.read(testSessionViewModelProvider);
    if (state.isAnswering || state.isSubmitting) {
      return;
    }
    final session = state.session;
    final currentIndex = session?.currentQuestionIndex;
    if (session == null || currentIndex == null) {
      return;
    }
    await ref
        .read(testSessionViewModelProvider.notifier)
        .submitAnswer(currentIndex, option.key);
  }

  Future<void> _goToPrevious(TestSessionState state) async {
    if (state.isNavigating || state.isAnswering || state.isSubmitting) {
      return;
    }
    final session = state.session;
    final currentIndex = session?.currentQuestionIndex;
    if (session == null || currentIndex == null) {
      return;
    }
    final target = currentIndex - 1;
    if (target < 0) {
      return;
    }
    await ref
        .read(testSessionViewModelProvider.notifier)
        .navigateQuestion(target);
  }

  Future<void> _goToNext(TestSessionState state) async {
    if (state.isNavigating || state.isAnswering || state.isSubmitting) {
      return;
    }
    final session = state.session;
    final currentIndex = session?.currentQuestionIndex;
    if (session == null || currentIndex == null) {
      return;
    }
    final total = session.questions.length;
    final nextIndex = currentIndex + 1;
    if (total > 0 && nextIndex >= total) {
      if (widget.readOnly) {
        return;
      }
      await _confirmSubmit(state);
      return;
    }
    await ref
        .read(testSessionViewModelProvider.notifier)
        .navigateQuestion(nextIndex);
  }

  Future<void> _confirmSubmit(TestSessionState state) async {
    if (widget.readOnly) {
      return;
    }
    final session = state.session;
    final questions = session?.questions ?? const <TestQuestion>[];
    final total = questions.length;
    final attempted = questions
        .where((question) =>
            question.selectedOptionKey != null &&
            question.selectedOptionKey!.isNotEmpty)
        .length;
    final notAttempted = math.max(total - attempted, 0);

    await showSubmitDialog(
      context,
      total: total,
      attempted: attempted,
      notAttempted: notAttempted,
      onConfirm: () async {
        Navigator.of(context).pop();
        await ref.read(testSessionViewModelProvider.notifier).submitTest();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ResultPage(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testSessionViewModelProvider);
    final session = state.session;
    final questions = session?.questions ?? const <TestQuestion>[];
    final currentIndex = session?.currentQuestionIndex;
    final question = (currentIndex != null &&
            currentIndex >= 0 &&
            currentIndex < questions.length)
        ? questions[currentIndex]
        : null;
    final isLoading = session == null || (state.isStarting && question == null);
    final totalQuestions = questions.length;
    final displayIndex = currentIndex != null ? currentIndex + 1 : 0;
    final isActionLocked =
        state.isNavigating || state.isAnswering || state.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title:
            totalQuestions > 0 ? '$displayIndex/$totalQuestions' : 'Mock Test',
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (question == null)
                    const Expanded(
                      child: Center(
                        child: CText(
                          'Loading questions...',
                          type: TextType.bodySmall,
                          color: AppColors.gray600,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else ...[
                    if (question.prompt.isNotEmpty)
                      CText(
                        question.prompt,
                        type: TextType.bodyMedium,
                        color: AppColors.black,
                        maxLines: 10,
                      ),
                    if (question.description != null &&
                        question.description!.isNotEmpty) ...[
                      AppSpacing.verticalSpaceSmall,
                      CText(
                        question.description!,
                        type: TextType.bodySmall,
                        color: AppColors.gray700,
                        maxLines: 10,
                      ),
                    ],
                    AppSpacing.verticalSpaceAverage,
                    Expanded(
                      child: OptionsList(
                        question: question,
                        selectedOptionKey: question.selectedOptionKey,
                        onOptionSelected: _handleOptionSelected,
                        readOnly: widget.readOnly ||
                            state.isAnswering ||
                            state.isSubmitting,
                      ),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: question == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(
                top: 0,
                bottom: 20,
                right: 20,
                left: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReusableButton(
                    borderColor: AppColors.black,
                    text: 'Previous',
                    textColor: AppColors.gray700,
                    backgroundColor: AppColors.white,
                    onPressed:
                        isActionLocked ? null : () => _goToPrevious(state),
                  ),
                  const Spacer(),
                  ReusableButton(
                    text: widget.readOnly
                        ? 'Next'
                        : (totalQuestions > 0 && displayIndex >= totalQuestions
                            ? 'Submit'
                            : 'Next'),
                    onPressed: isActionLocked
                        ? null
                        : () {
                            if (widget.readOnly) {
                              _goToNext(state);
                              return;
                            }
                            if (totalQuestions > 0 &&
                                displayIndex >= totalQuestions) {
                              _confirmSubmit(state);
                            } else {
                              _goToNext(state);
                            }
                          },
                  ),
                ],
              ),
            ),
    );
  }
}
