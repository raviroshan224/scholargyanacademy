import 'package:flutter/material.dart';
import '../../../../core/core.dart';

class RemarksSection extends StatelessWidget {
  final String remarks;

  const RemarksSection({super.key, required this.remarks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CText(
          'Remarks:',
          type: TextType.bodyMedium,
          color: AppColors.gray800,
        ),
        const SizedBox(height: 8),
        CText(
          remarks,
          type: TextType.bodySmall,
        ),
      ],
    );
  }
}
