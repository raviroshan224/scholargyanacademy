import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/core.dart';

class ProfileTextRow extends StatelessWidget {
  final String cardTitle;
  final Color? titleColor;
  final Color? subTitleColor;
  final String? cardSubTitle;
  final bool? showSubTitle;
  final bool? hideArrow;
  final VoidCallback? onClick;
  final String icon;
  final VoidCallback onPressed;
  final bool isLoading;

  const ProfileTextRow({
    super.key,
    required this.onPressed,
    required this.cardTitle,
    this.cardSubTitle,
    this.showSubTitle,
    this.onClick,
    this.titleColor,
    this.subTitleColor,
    this.hideArrow,
    required this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8),
        child: Row(
          children: [
            SvgPicture.asset(icon),
            AppSpacing.horizontalSpaceAverage,
            CText(
              cardTitle,
              type: TextType.bodyMedium,
              color: titleColor ?? AppColors.gray600,
            ),
            Spacer(),
            InkWell(
              onTap: isLoading ? null : (onClick ?? onPressed),
              child: SvgPicture.asset(
                AppAssets.forwardIcon,
                colorFilter: isLoading
                    ? const ColorFilter.mode(
                        AppColors.gray400,
                        BlendMode.srcIn,
                      )
                    : null,
              ),
            )
          ],
        ),
      ),
    );
  }
}
