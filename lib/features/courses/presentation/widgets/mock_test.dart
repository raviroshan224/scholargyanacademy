import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/core.dart';
import '../../../test/presentation/pages/detail_pages/test_details.dart';
import '../../../test/models/mock_test_models.dart';
import '../../model/course_models.dart';
import '../../view_model/course_view_model.dart';

class MockTestList extends ConsumerWidget {
  const MockTestList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coursesViewModelProvider);
    final isEnrolled = state.isEnrolled;
    List<MockTestModel> tests = state.mockTests;
    if (tests.isEmpty) {
      tests = _fallbackMockTests(state.details);
    }

    final isLoading =
        (state.loadingMockTests || state.loadingDetails) && tests.isEmpty;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.mockTestsError != null && tests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CText(
            state.mockTestsError!.message,
            type: TextType.bodyMedium,
            color: AppColors.failure,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (tests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CText(
            'Mock tests will be available once they are published for this course.',
            type: TextType.bodyMedium,
            color: AppColors.gray600,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final test = tests[index];
        final title =
            test.title.isNotEmpty ? test.title : 'Mock Test ${index + 1}';
        final description = test.description;
        final totalQuestions = test.resolvedQuestionCount;
        final duration = test.durationLabel;

        void handleStart() {
          if (!isEnrolled) {
            AppMethods.showCustomSnackBar(
              context: context,
              message: 'Please enroll to access this content.',
              isError: true,
            );
            return;
          }

          // Navigate to Test Detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TestDetailsPage(
                initialTest: MockTest(
                  id: test.id,
                  courseId: test.courseId ?? '',
                  title: test.title,
                  description: test.description,
                  numberOfQuestions: test.resolvedQuestionCount,
                  durationMinutes: test.durationMinutes,
                  extra: test.raw,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SvgPicture.asset(
                        AppAssets.courseSelectionIcon,
                        height: 16,
                        width: 16,
                      ),
                    ),
                  ),
                  AppSpacing.horizontalSpaceLarge,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CText(title,
                            type: TextType.bodyMedium,
                            color: AppColors.black,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        if ((description ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: CText(
                              description!,
                              type: TextType.bodySmall,
                              color: AppColors.gray600,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        AppSpacing.verticalSpaceTiny,
                        Row(
                          children: [
                            if (totalQuestions != null)
                              CText('$totalQuestions Questions',
                                  type: TextType.bodySmall,
                                  color: AppColors.gray500),
                            if (totalQuestions != null && duration != null)
                              const SizedBox(width: 12),
                            if (duration != null)
                              CText(duration,
                                  type: TextType.bodySmall,
                                  color: AppColors.gray500),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.horizontalSpaceSmall,
                  ReusableButton(
                    backgroundColor:
                        isEnrolled ? AppColors.secondary : AppColors.gray300,
                    text: 'Start',
                    textColor: isEnrolled ? AppColors.white : AppColors.gray600,
                    onPressed: handleStart,
                  ),
                ],
              ),
              AppSpacing.verticalSpaceSmall,
              const Divider(color: AppColors.gray300, thickness: 0.5),
            ],
          ),
        );
      },
    );
  }

  List<MockTestModel> _fallbackMockTests(Map<String, dynamic>? details) {
    if (details == null) return const <MockTestModel>[];
    final List<MockTestModel> results = [];

    void parse(dynamic source) {
      if (source is List) {
        for (final item in source) {
          if (item is Map<String, dynamic>) {
            results.add(MockTestModel.fromJson(item));
          } else if (item is Map) {
            results.add(
              MockTestModel.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
    }

    parse(details['mockTests']);
    if (results.isEmpty) parse(details['mocktests']);
    if (results.isEmpty) parse(details['tests']);
    if (results.isEmpty) parse(details['exams']);

    final enrollment = details['enrollmentDetails'];
    if (results.isEmpty && enrollment is Map<String, dynamic>) {
      parse(enrollment['mockTests']);
    } else if (results.isEmpty && enrollment is Map) {
      final map = Map<String, dynamic>.from(enrollment);
      parse(map['mockTests']);
    }

    return results;
  }
}
