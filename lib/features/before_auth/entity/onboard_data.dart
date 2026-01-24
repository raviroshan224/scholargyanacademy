import '../../../core/core.dart';

class OnboardingData {
  final String title;
  final String description;
  final String image;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });
}

final List<OnboardingData> onboardingData = [
  OnboardingData(
    title: "Welcome to Loksewa Learning",
    description: "Highlights speed and ease of learning Loksewa courses.",
    image: AppAssets.onboardPictureOne, // Replace with your SVG file path
  ),
  OnboardingData(
    title: "Excel in Loksewa Exams",
    description: "Emphasizes accessibility and quality of lessons.",
    image: AppAssets.onboardPictureTwo, // Replace with your SVG file path
  ),
];
