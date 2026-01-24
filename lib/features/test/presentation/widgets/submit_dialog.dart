import 'package:flutter/material.dart';
import '../../../../core/core.dart';

Future<void> showSubmitDialog(
  BuildContext context, {
  required int total,
  required int attempted,
  required int notAttempted,
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const CText(
          'Would you like to submit your answer?',
          type: TextType.bodyLarge,
          color: AppColors.black,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow('Total', total),
            _buildRow('Attempted', attempted),
            _buildRow('Not Attempted', notAttempted),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 90,
                child: ReusableButton(
                    backgroundColor: AppColors.white,
                    borderColor: AppColors.gray600,
                    text: "Cancel",
                    textColor: AppColors.gray800,
                    onPressed: () {
                      Navigator.pop(context);
                      onCancel?.call();
                    }),
              ),
              SizedBox(
                width: 90,
                child: ReusableButton(
                    text: "Submit",
                    onPressed: () {
                      onConfirm();
                    }),
              ),
            ],
          )
        ],
      );
    },
  );
}

Widget _buildRow(String label, int value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CText(label, type: TextType.bodyMedium),
        CText(value.toString(), type: TextType.bodyMedium),
      ],
    ),
  );
}
