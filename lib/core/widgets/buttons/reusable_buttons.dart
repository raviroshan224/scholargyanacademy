import 'package:flutter/material.dart';

import '../../constant/app_colors.dart';
import '../../utils/ui_helper/app_spacing.dart';
import '../text/custom_text.dart';

class ReusableButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final TextStyle? textStyle;
  final Color? borderColor;
  final Color? textColor;
  final double? borderWidth;
  final FontWeight? fontWeight;
  final Widget? btnIcon;
  final Widget? suffixIcon;
  final TextType? textType;
  final double? borderRadius;
  final double? verticalBtnHeight;
  final BorderRadius? borderRadiusCust;
  final MainAxisAlignment? alignmentForText;
  final bool isLoading;

  const ReusableButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.backgroundGradient,
    this.textStyle,
    this.borderColor,
    this.textColor,
    this.borderWidth,
    this.btnIcon,
    this.textType,
    this.fontWeight,
    this.suffixIcon,
    this.borderRadius,
    this.borderRadiusCust,
    this.alignmentForText,
    this.verticalBtnHeight,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 48.0,
        padding: EdgeInsets.symmetric(
            vertical: verticalBtnHeight ?? 4.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.secondary,
          gradient: backgroundGradient,
          borderRadius: borderRadiusCust ?? BorderRadius.circular(borderRadius ?? 8.0),
          border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: borderWidth ?? 0.0,
          ),
        ),
        child: Center(
          child: isLoading
              ? CircularProgressIndicator(color: textColor ?? AppColors.white)
              : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: alignmentForText == null ? 4.0 : 0.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        alignmentForText ?? MainAxisAlignment.center,
                    children: [
                      btnIcon ?? const SizedBox.shrink(),
                      alignmentForText == null
                          ? AppSpacing.horizontalSpaceSmall
                          : const SizedBox.shrink(),
                      CText(
                        text,
                        type: textType ?? TextType.titleLarge,
                        fontWeight: fontWeight,
                        color: textColor ?? AppColors.white,
                      ),
                      AppSpacing.horizontalSpaceSmall,
                      suffixIcon ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
