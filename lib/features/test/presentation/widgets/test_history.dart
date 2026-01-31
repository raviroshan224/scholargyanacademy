import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../models/test_session_models.dart';

String _formatDateTime(DateTime value) {
  return DateFormat('d MMM y, h:mm a').format(value.toLocal());
}

class TestHistory extends StatelessWidget {
  const TestHistory({
    super.key,
    required this.sessions,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onHistoryTap,
  });

  final List<TestHistoryItem> sessions;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final void Function(TestHistoryItem item) onHistoryTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading && sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Builder(
        builder: (context) {
          if (errorMessage != null && sessions.isEmpty) {
            return ListView(
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
            );
          }

          if (sessions.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CText(
                    'No test history yet. Start a mock test to see results here.',
                    type: TextType.bodySmall,
                    color: AppColors.gray600,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = sessions[index];
              final percent = item.percentage != null
                  ? '${item.percentage!.toStringAsFixed(1)}%'
                  : item.score != null
                      ? '${item.score}'
                      : '-';
              final completedAt = item.completedAt != null
                  ? _formatDateTime(item.completedAt!)
                  : 'Not available';

              final isPassed = item.passed == true;
              final statusColor = isPassed ? AppColors.success : AppColors.failure;
              final statusText = isPassed ? 'Passed' : 'Failed';

              return InkWell(
                onTap: () => onHistoryTap(item),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CText(
                              percent,
                              type: TextType.titleSmall,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                            if (item.passed != null) ...[
                              AppSpacing.verticalSpaceTiny,
                              CText(
                                statusText,
                                type: TextType.bodySmall,
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ],
                        ),
                      ),
                      AppSpacing.horizontalSpaceMedium,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CText(
                              item.mockTestTitle ?? item.examTitle ?? 'Mock Test',
                              type: TextType.bodyMedium,
                              color: AppColors.black,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.w600,
                            ),
                            AppSpacing.verticalSpaceSmall,
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppColors.gray600,
                                ),
                                AppSpacing.horizontalSpaceTiny,
                                CText(
                                  completedAt,
                                  type: TextType.bodySmall,
                                  color: AppColors.gray600,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.gray400,
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(
              color: AppColors.gray300,
              thickness: 0.6,
              height: 0,
            ),
            itemCount: sessions.length,
          );
        },
      ),
    );
  }
}
