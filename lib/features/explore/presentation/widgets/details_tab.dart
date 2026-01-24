import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../test/view_model/exam_view_model.dart';

class DetailsTab extends ConsumerWidget {
  const DetailsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examState = ref.watch(examViewModelProvider);
    final exam = examState.selectedExam;
    final meta = exam?.metadata ?? const {};

    int? daysRemaining;
    if (exam?.validTo != null) {
      final now = DateTime.now();
      final diff = exam!.validTo!.difference(now).inDays;
      daysRemaining = diff > 0 ? diff : 0;
    }

    final categoryName =
        (meta['categoryName']?.toString()) ?? (meta['category']?.toString());

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Edit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CText('Exam Details',
                  type: TextType.bodyLarge, color: AppColors.black),
              TextButton(
                onPressed: () {
                  // TODO: navigate to edit screen when available
                },
                child: CText('Edit',
                    type: TextType.bodySmall, color: AppColors.secondary),
              ),
            ],
          ),
          AppSpacing.verticalSpaceSmall,

          // Quick lines / instructions
          if (examState.loadingDetail)
            const Center(child: CircularProgressIndicator())
          else if (exam != null && exam.instructions.isNotEmpty) ...[
            CText(exam.instructions.elementAt(0), type: TextType.bodySmall),
            if (exam.instructions.length > 1)
              CText(exam.instructions.elementAt(1), type: TextType.bodySmall),
          ] else ...[
            CText('Neque quidem reprehe', type: TextType.bodySmall),
            CText('Neque quidem reprehe', type: TextType.bodySmall),
          ],

          AppSpacing.verticalSpaceSmall,

          // Category & validity
          if (categoryName != null && categoryName.isNotEmpty)
            CText('Category: $categoryName', type: TextType.bodySmall)
          else
            CText('Category: -', type: TextType.bodySmall),
          AppSpacing.verticalSpaceTiny,
          CText(
            'Invalid After: ${daysRemaining != null ? '$daysRemaining days' : 'N/A'}',
            type: TextType.bodySmall,
          ),

          AppSpacing.verticalSpaceSmall,

          // Description
          CText('Description :',
              type: TextType.bodyLarge, color: AppColors.black),
          AppSpacing.verticalSpaceTiny,
          CText(
            exam?.description ?? 'Nostrum doloribus se.',
            type: TextType.bodySmall,
          ),

          AppSpacing.verticalSpaceLarge,

          // Course List
          CText('Course List:',
              type: TextType.bodyLarge, color: AppColors.black),
          AppSpacing.verticalSpaceSmall,
          if (exam != null && exam.courses.isNotEmpty)
            ...exam.courses
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CText(c.title, type: TextType.bodySmall),
                          CText(c.title, type: TextType.bodySmall),
                          CText('No classes yet',
                              type: TextType.bodySmall,
                              color: AppColors.gray600),
                        ],
                      ),
                    ))
                .toList()
          else ...[
            CText('Database engineerings', type: TextType.bodySmall),
            CText('Database engineerings', type: TextType.bodySmall),
            CText('No classes yet',
                type: TextType.bodySmall, color: AppColors.gray600),
            AppSpacing.verticalSpaceSmall,
            CText('Kharidar 2nd paper', type: TextType.bodySmall),
            CText('Kharidar 2nd paper', type: TextType.bodySmall),
            CText('No classes yet',
                type: TextType.bodySmall, color: AppColors.gray600),
            AppSpacing.verticalSpaceSmall,
            CText('Agentic AI course', type: TextType.bodySmall),
            CText('Agentic AI course', type: TextType.bodySmall),
            CText('No classes yet',
                type: TextType.bodySmall, color: AppColors.gray600),
          ],
        ],
      ),
    );
  }
}
