import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/services/remote_services/api_endpoints.dart';
import '../../../../../core/core.dart';
import '../../../../courses/presentation/pages/enrolled_course_details_page.dart';
import '../../../provider/slider_provider.dart';
import '../../../view_model/homepage_view_model.dart';
import 'image_slider.dart';

class HomeSliders extends ConsumerWidget {
  const HomeSliders({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homepageViewModelProvider);
    final currentIndex = ref.watch(currentSlideIndexProvider);

    // Build images from homepage bannerCourses
    final banners = homeState.bannerCourses;
    final imageSliders = <Widget>[];
    for (final c in banners) {
      final u = _toAbsoluteUrl(c.courseImageUrl);
      if (u == null) continue;

      imageSliders.add(
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ImageSlider(
            imageName: u,
            propId: c.id?.toString() ?? '',
            fit: BoxFit.cover,
            disableImagePreview: true,
            onTap: () {
              final courseId = c.id?.toString();
              if (courseId == null || courseId.isEmpty) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EnrolledCourseDetailsPage(courseId: courseId),
                ),
              );
            },
          ),
        ),
      );
    }

    if (homeState.loading && imageSliders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // If no banners from bannerCourses, try recommendedCourses as a fallback
    if (imageSliders.isEmpty) {
      final fallback = homeState.recommendedCourses;
      for (final c in fallback) {
        final u = _toAbsoluteUrl(c.courseImageUrl);
        if (u == null) continue;

        imageSliders.add(
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ImageSlider(
              imageName: u,
              propId: c.id?.toString() ?? '',
              fit: BoxFit.cover,
              disableImagePreview: true,
              onTap: () {
                final courseId = c.id?.toString();
                if (courseId == null || courseId.isEmpty) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        EnrolledCourseDetailsPage(courseId: courseId),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    if (imageSliders.isEmpty) {
      // Still empty after fallback; render nothing
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Stack(
          children: [
            CarouselSlider(
              items: imageSliders,
              options: CarouselOptions(
                aspectRatio: 16 / 9,
                autoPlay: true,
                enableInfiniteScroll: true,
                viewportFraction: 1,
                padEnds: true,
                onPageChanged: (index, reason) {
                  ref.read(currentSlideIndexProvider.notifier).state = index;
                },
              ),
            ),
            Positioned(
              right: 8,
              left: 8,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imageSliders.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      ref.read(currentSlideIndexProvider.notifier).state =
                          index;
                    },
                    child: Container(
                      width: currentIndex == index ? 16 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentIndex == index
                              ? AppColors.primary
                              : AppColors.gray300,
                        ),
                        color: currentIndex == index
                            ? AppColors.primary
                            : AppColors.gray300,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        AppSpacing.verticalSpaceLarge,
      ],
    );
  }
}

String? _toAbsoluteUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return trimmed;
  }
  // If backend returns only a filename, prefix with configured image base URL
  return ApiEndPoints.imageBaseUrl + trimmed;
}
