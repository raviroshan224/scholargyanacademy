import 'package:flutter/material.dart';
import '../../core.dart';

class TitleTextRow extends StatelessWidget {
  final String cardTitle;
  final Color? titleColor;
  final Color? subTitleColor;
  final String? cardSubTitle;
  final bool? showSubTitle;
  final bool? hideArrow;
  final VoidCallback? onClick;

  const TitleTextRow(
      {super.key,
      required this.cardTitle,
      this.cardSubTitle,
      this.showSubTitle,
      this.onClick,
      this.titleColor,
      this.subTitleColor,
      this.hideArrow});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CText(
          cardTitle,
          type: TextType.headlineMedium,
          color: titleColor ?? AppColors.heading,
        ),
        showSubTitle ?? true
            ? InkWell(
                onTap: onClick,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: CText(
                        cardSubTitle ?? '',
                        type: TextType.bodyMedium,
                        color: subTitleColor ?? AppColors.gray600,
                      ),
                    ),
                    CText("See All",
                        type: TextType.bodyMedium, color: AppColors.gray600),
                    AppSpacing.horizontalSpaceTiny,
                    (hideArrow ?? false)
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.heading,
                            size: 14,
                          )
                  ],
                ),
              )
            : const SizedBox.shrink()
      ],
    );
  }
}
