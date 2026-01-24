import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../constant/app_assets.dart';

class CustomCachedNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit? fitStatus;
  final String? errorImage;
  final Size? size;

  const CustomCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.size,
    this.fitStatus,
    this.errorImage,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: CachedNetworkImage(
        height: size?.height,
        width: size?.width,
        imageUrl: imageUrl ?? '',
        fit: fitStatus ?? BoxFit.fill,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => ClipRRect(
          child: Image.asset(
            errorImage ?? AppAssets.errorImage,
            height: size?.height,
            width: size?.width,
            fit: fitStatus ?? BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
