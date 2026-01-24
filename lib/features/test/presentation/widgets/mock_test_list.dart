import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../models/mock_test_models.dart';

class MockTestListView extends StatelessWidget {
  const MockTestListView({
    super.key,
    required this.tests,
    required this.isLoading,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onTestTap,
    required this.onStartTest,
  });

  final List<MockTest> tests;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(MockTest test) onTestTap;
  final void Function(MockTest test) onStartTest;

  @override
  Widget build(BuildContext context) {
    if (isLoading && tests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && tests.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CText(
                    errorMessage!,
                    type: TextType.bodySmall,
                    color: AppColors.failure,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.verticalSpaceMedium,
                  ReusableButton(
                    text: 'Retry',
                    onPressed: () {
                      onRefresh();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (tests.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.all(24.0),
              child: CText(
                'No tests available for this course.',
                type: TextType.bodySmall,
                color: AppColors.gray600,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 120 &&
              !isLoadingMore) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: tests.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= tests.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final mockTest = tests[index];
            final questionCount = mockTest.numberOfQuestions;
            final duration = mockTest.durationMinutes;
            
            final attemptsRemaining = mockTest.remainingAttempts;
            final attemptsAllowed = mockTest.attemptsAllowed;
            final attemptsText = attemptsAllowed != null
                ? '${ attemptsRemaining ?? attemptsAllowed}/$attemptsAllowed'
                : attemptsRemaining != null
                    ? '$attemptsRemaining'
                    : null;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.gray200, width: 1),
              ),
              child: InkWell(
                onTap: () => onTestTap(mockTest),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      CText(
                        mockTest.title ?? 'Untitled Test',
                        type: TextType.titleMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.verticalSpaceMedium,
                      
                      // Info row
                      Row(
                        children: [
                          if (questionCount != null && questionCount > 0) ...[
                            Icon(Icons.quiz_outlined, size: 16, color: AppColors.gray600),
                            const SizedBox(width: 4),
                            CText(
                              '$questionCount Questions',
                              type: TextType.bodySmall,
                              color: AppColors.gray700,
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (duration != null && duration > 0) ...[
                            Icon(Icons.access_time, size: 16, color: AppColors.gray600),
                            const SizedBox(width: 4),
                            CText(
                              '$duration min',
                              type: TextType.bodySmall,
                              color: AppColors.gray700,
                            ),
                          ],
                          const Spacer(),
                          if (attemptsText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gray100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CText(
                                '$attemptsText attempts',
                                type: TextType.bodySmall,
                                color: AppColors.gray700,
                              ),
                            ),
                        ],
                      ),
                      AppSpacing.verticalSpaceMedium,
                      
                      // CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => onStartTest(mockTest),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mockTest.canTakeTest 
                                ? AppColors.primary 
                                : AppColors.gray300,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: CText(
                            mockTest.canTakeTest ? 'Start Test' : 'View Details',
                            type: TextType.bodyMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
