import 'package:flutter/material.dart';

import '../../constant/app_assets.dart';

class BuildCircularImage extends StatelessWidget {
  const BuildCircularImage({
    super.key,
    required this.photoUrl,
    this.imageRadius = 24.0,
    this.errorImgUrl,
  });

  final String photoUrl;
  final double imageRadius;
  final String? errorImgUrl;

  @override
  Widget build(BuildContext context) {
    final double size = imageRadius * 2;

    return ClipOval(
      child: Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.fill,
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          return Image.asset(
            errorImgUrl ?? AppAssets.defaultPicture,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
