import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../core/widgets/images/slider_preview.dart';

class ImageSlider extends ConsumerWidget {
  const ImageSlider({
    super.key,
    this.width,
    required this.imageName,
    this.fit,
    required this.propId,
    this.disableImagePreview,
    this.linkAttached,
    this.onTap,
  });

  final double? width;
  final String imageName;
  final String propId;
  final BoxFit? fit;
  final String? linkAttached;
  final bool? disableImagePreview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap ??
          ((disableImagePreview ?? false)
              ? () {
                  if (linkAttached != null && linkAttached!.isNotEmpty) {
                    AppMethods.urlLauncherHelper(context, linkAttached);
                  }
                }
              : () {
                  showDialog(
                      context: context,
                      builder: (x) => SliderPreview(
                            images: [imageName],
                            index: 0,
                            isNetworkImage: true,
                          ));
                }),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: SizedBox.expand(
            child: CustomCachedNetworkImage(
              imageUrl: imageName,
              fitStatus: fit ?? BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
