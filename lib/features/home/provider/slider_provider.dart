import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/core.dart';

final currentSlideIndexProvider = StateProvider<int>((Ref ref) => 0);

class SliderResponse {
  final List<SliderItem>? slider;

  SliderResponse({this.slider});
}

class SliderItem {
  final int id;
  final FeatureImage? featureImage;
  final String? link;

  SliderItem({required this.id, this.featureImage, this.link});
}

class FeatureImage {
  final String? url;

  FeatureImage({this.url});
}

final homeSliderProvider = FutureProvider<SliderResponse>((Ref ref) async {
  await Future.delayed(const Duration(seconds: 1));

  return SliderResponse(
    slider: [
      SliderItem(
        id: 1,
        featureImage: FeatureImage(
            url:
                'https://knowledge.hubspot.com/hubfs/freeonlinecourses-1.webp'),
        link: 'https://property1.com',
      ),
      SliderItem(
        id: 2,
        featureImage: FeatureImage(
          url: AppAssets.networkImgTwo,
        ),
        link:
            'https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.globalcareercounsellor.com%2Fblog%2Fadvantages-of-pursuing-an-online-course%2F&psig=AOvVaw2kmovjMpA9V3qXNHY38DsR&ust=1732775492210000&source=images&cd=vfe&opi=89978449&ved=0CBQQjRxqFwoTCJi-6ojy-4kDFQAAAAAdAAAAABAE',
      ),
      SliderItem(
        id: 3,
        featureImage: FeatureImage(
          url:
              'https://instructor-academy.onlinecoursehost.com/content/images/2023/05/How-to-Create-an-Online-Course-For-Free--Complete-Guide--6.jpg',
        ),
        link: 'https://property3.com',
      ),
    ],
  );
});
