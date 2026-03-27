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
  // Slider data is loaded via the homepage view model from the API.
  // No hardcoded external links or dummy data here.
  return SliderResponse(slider: []);
});
