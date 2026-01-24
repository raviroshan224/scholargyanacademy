import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../models/exam_models.dart';

class AvailableList extends StatelessWidget {
  const AvailableList({
    super.key,
    required this.exams,
    required this.isLoading,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onExamTap,
  });

  final List<ExamListItem> exams;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(ExamListItem exam) onExamTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading && exams.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && exams.isEmpty) {
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

    if (exams.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.all(24.0),
              child: CText(
                'No exams available right now. Please check back later.',
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: exams.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= exams.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final exam = exams[index];
            final chips = _buildMetaChips(exam);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 1,
              child: InkWell(
                onTap: () => onExamTap(exam),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 68,
                          width: 68,
                          child: CustomCachedNetworkImage(
                            imageUrl:
                                exam.thumbnailUrl ?? AppAssets.dummyNetImg,
                            fitStatus: BoxFit.cover,
                          ),
                        ),
                      ),
                      AppSpacing.horizontalSpaceMedium,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CText(
                              exam.title,
                              type: TextType.bodyLarge,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (exam.subtitle?.isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: CText(
                                  exam.subtitle!,
                                  type: TextType.bodySmall,
                                  color: AppColors.gray600,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (chips.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: chips
                                      .map(
                                        (item) => Chip(
                                          label: CText(
                                            item,
                                            type: TextType.bodySmall,
                                            color: AppColors.gray700,
                                          ),
                                          backgroundColor: AppColors.gray100,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      AppSpacing.horizontalSpaceSmall,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CText(
                            _formatPrice(exam),
                            type: TextType.bodyMedium,
                            fontWeight: FontWeight.w600,
                            color: (exam.isFree ?? false)
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          if (exam.validTo != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: CText(
                                'Valid till ${DateFormat('dd MMM yyyy').format(exam.validTo!)}',
                                type: TextType.bodySmall,
                                color: AppColors.gray600,
                              ),
                            ),
                        ],
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

  List<String> _buildMetaChips(ExamListItem exam) {
    final chips = <String>[];
    if (exam.categoryName?.isNotEmpty == true) {
      chips.add(exam.categoryName!);
    }
    if (exam.totalQuestions != null) {
      chips.add('${exam.totalQuestions} questions');
    }
    if (exam.durationMinutes != null) {
      chips.add('${exam.durationMinutes} mins');
    }
    if (exam.status?.isNotEmpty == true) {
      chips.add(exam.status!);
    }
    return chips;
  }

  String _formatPrice(ExamListItem exam) {
    if ((exam.isFree ?? false) || (exam.price ?? 0) == 0) {
      return 'Free';
    }
    final price = exam.price ?? 0;
    if (price == price.roundToDouble()) {
      return 'Rs. ${price.toInt()}';
    }
    return 'Rs. ${price.toStringAsFixed(2)}';
  }
}
