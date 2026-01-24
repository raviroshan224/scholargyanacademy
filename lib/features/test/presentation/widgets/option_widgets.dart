import 'package:flutter/material.dart';
import '../../../../core/core.dart';

class OptionWidget extends StatelessWidget {
  final String text;
  final bool isCorrect;
  final bool isSelected;

  const OptionWidget({
    super.key,
    required this.text,
    required this.isCorrect,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (isCorrect) {
      backgroundColor = AppColors.successWithOpacity(0.2);
    } else if (isSelected) {
      backgroundColor = Colors.blue.withOpacity(0.2);
    } else {
      backgroundColor = Colors.transparent;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color:
              isCorrect || isSelected ? AppColors.gray400 : AppColors.gray400,
        ),
      ),
      child: CText(text,
          color: isCorrect ? Colors.green : AppColors.gray700,
          type: TextType.bodyMedium),
    );
  }
}
