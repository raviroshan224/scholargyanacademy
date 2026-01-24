import 'package:flutter/material.dart';
import '../../../../core/core.dart';

class ProgressCircle extends StatelessWidget {
  final int percentage;

  const ProgressCircle({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      width:80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 12,
            backgroundColor: AppColors.gray200,
            color: AppColors.primary,
          ),
          Center(
            child: CText(
              '$percentage%',
              type: TextType.bodyLarge,
              color: AppColors.gray800,
            ),
          ),
        ],
      ),
    );
  }
}
