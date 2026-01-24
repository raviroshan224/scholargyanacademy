import 'package:flutter/material.dart';
import '../../../../core/core.dart';

class DetailsCard extends StatelessWidget {
  final int totalQuestions;
  final int attempted;
  final int correct;
  final int incorrect;

  const DetailsCard({
    super.key,
    required this.totalQuestions,
    required this.attempted,
    required this.correct,
    required this.incorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Total Questions: ', totalQuestions),
            _buildRow('Attempted Questions: ', attempted),
            _buildRow('Correct Answers: ', correct),
            _buildRow('Incorrect Answers: ', incorrect),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CText(label, type: TextType.bodyMedium, color: AppColors.gray700),
        AppSpacing.horizontalSpaceLarge,
          CText(value.toString(), type: TextType.titleMedium),
        ],
      ),
    );
  }
}
