import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../models/test_session_models.dart';

class OptionsList extends StatelessWidget {
  const OptionsList({
    super.key,
    required this.question,
    required this.selectedOptionKey,
    required this.onOptionSelected,
    this.readOnly = false,
  });

  final TestQuestion question;
  final String? selectedOptionKey;
  final void Function(TestQuestionOption option) onOptionSelected;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (question.options.isEmpty) {
      return const Center(
        child: CText(
          'No options available for this question.',
          type: TextType.bodySmall,
          color: AppColors.gray600,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = selectedOptionKey == option.key;
        return GestureDetector(
          onTap: readOnly
              ? null
              : () {
                  onOptionSelected(option);
                },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : AppColors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.gray300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CText(
                  '${String.fromCharCode(65 + index)}.',
                  type: TextType.bodyMedium,
                  color: AppColors.primary,
                ),
                AppSpacing.horizontalSpaceSmall,
                Expanded(
                  child: CText(
                    option.label,
                    type: TextType.bodyMedium,
                    color: AppColors.gray700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
