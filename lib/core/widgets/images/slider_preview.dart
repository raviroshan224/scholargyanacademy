import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../core.dart';

class SliderPreview extends StatefulWidget {
  final List<String> images;
  final int index;
  final bool isNetworkImage;
  const SliderPreview({
    super.key,
    required this.images,
    required this.index,
    this.isNetworkImage = true,
  });

  @override
  State<SliderPreview> createState() => _SliderPreviewState();
}

class _SliderPreviewState extends State<SliderPreview> {
  late final PageController pageController;
  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.index, viewportFraction: 1, keepPage: true);
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: PhotoViewGallery.builder(
        pageController: pageController,
        backgroundDecoration: const BoxDecoration(),
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(AppAssets.errorImage);
            },
            imageProvider: widget.isNetworkImage
                ? CachedNetworkImageProvider(
              widget.images[index],
            )
                : FileImage(
              File(widget.images[index]),
            ) as ImageProvider,
          );
        },
        itemCount: widget.images.length,
      ),
    );
  }
}
