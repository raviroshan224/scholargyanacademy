import 'package:flutter/material.dart';
import '../../../../core/core.dart';

class WhatsIncluded extends StatelessWidget {
  const WhatsIncluded({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.gray200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: CText("At eget nunc et et nulla.", 
                      type: TextType.bodyMedium,
                      color: AppColors.black),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
