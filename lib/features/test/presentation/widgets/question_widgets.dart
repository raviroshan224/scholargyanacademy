import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../test.dart';


class QuestionWidget extends StatelessWidget {
  final Question question;
  final int index;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CText(
              "$index. ${question.text}",
             type: TextType.bodyMedium, color:AppColors.black
            ),
            AppSpacing.verticalSpaceAverage,
            ...List.generate(
              question.options.length,
                  (i) => OptionWidget(
                text: question.options[i],
                isCorrect: i == question.correctOptionIndex,
                isSelected: i == question.selectedOptionIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
