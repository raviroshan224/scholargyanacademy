import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;

  final Function()? onLeadingIconClick;
  final Widget? leadingIcon;
  final bool showLeading;
  final Color? appBarColor, titleColor, surfaceColor;
  final List<Widget>? actions;
  final double? leadingWidth;
  final Widget? titleWidget;
  final bool centerTitle;
  final double? appBarElevation;
  final double? custPreferredSize;
  final PreferredSizeWidget? bottom;

  const CustomAppBar(
      {super.key,
      this.title,
      this.leadingWidth = 64,
      this.onLeadingIconClick,
      this.leadingIcon,
      this.appBarColor,
      this.titleColor = AppColors.white,
      this.actions,
      this.titleWidget,
      this.centerTitle = false,
      this.surfaceColor,
      this.appBarElevation,
      this.showLeading = false,
      this.custPreferredSize,
      this.bottom});

  @override
  Size get preferredSize => Size.fromHeight(custPreferredSize ?? 58);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      elevation: appBarElevation ?? 4,
      backgroundColor: appBarColor ?? AppColors.white,
      surfaceTintColor: surfaceColor ?? AppColors.white,
      iconTheme: IconThemeData(
        color: AppColors.primary,
      ),
      leading: showLeading
          ? Image.asset("assets/pictures/courseselection.png")
          : null,
      title: titleWidget ??
          CText(
            title ?? '',
            type: TextType.headlineMedium,
            color: AppColors.black,
            textAlign: TextAlign.start,
            // style: context.titleSmall,
          ),
      centerTitle: centerTitle,
      actions: actions ??
          [
            // Padding(
            //   padding: const EdgeInsets.only(right: 16.0),
            //   child: InkWell(
            //     onTap: () {
            //       Navigator.push(context,
            //           MaterialPageRoute(builder: (builder) => ProfilePage()));
            //     },
            //     child: BuildCircularImage(
            //       photoUrl: AppAssets.dummyNetImg,
            //       imageRadius: 22.0,
            //     ),
            //   ),
            // ),
          ],
      bottom: bottom,
    );
  }
}
