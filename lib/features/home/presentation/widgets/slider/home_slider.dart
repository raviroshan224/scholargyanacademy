import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/core.dart';
import '../../../home.dart';


class HomeSliders extends ConsumerWidget {
  const HomeSliders({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slidersAsync = ref.watch(homeSliderProvider);
    final currentIndex = ref.watch(currentSlideIndexProvider);
    return Column(
      children: [
        slidersAsync.when(
          data: (sliders) {
            final imageSliders = sliders.slider
                    ?.where(
                        (item) => item.featureImage?.url?.isNotEmpty ?? false)
                    .map((item) => ImageSlider(
                          imageName: item.featureImage!.url!,
                          propId: item.id.toString(),
                          fit: BoxFit.cover,
                          disableImagePreview: true,
                          linkAttached: item.link,
                        ))
                    .toList() ??
                [];

            return Stack(
              children: [
                CarouselSlider(
                  items: imageSliders,
                  options: CarouselOptions(
                    autoPlay: true,
                    enableInfiniteScroll: true,
                    viewportFraction: 1,
                    padEnds: true,
                    onPageChanged: (index, reason) {
                      ref.read(currentSlideIndexProvider.notifier).state =
                          index;
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
            );
          },
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        AppSpacing.verticalSpaceLarge,
      ],
    );
  }
}
