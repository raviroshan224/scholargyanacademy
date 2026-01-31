import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../core/core.dart';
import '../../../auth/view/pages/login_page.dart';
import '../../before_auth.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  _OnBoardingPageState createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    padding: EdgeInsets.all(0.0),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseSelection(),
                        ),
                      );
                    },
                    icon: Row(
                      children: [
                        CText(
                          "Skip",
                          type: TextType.bodySmall,
                          color: AppColors.black,
                        ),
                        AppSpacing.horizontalSpaceTiny,
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.black,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingData.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final data = onboardingData[index];
                    return OnboardingWidget(
                      title: data.title,
                      description: data.description,
                      image: data.image,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 12.0,
                ),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: onboardingData.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppColors.primary,
                    dotColor: AppColors.gray300,
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 8,
                  ),
                ),
              ),
              AppSpacing.verticalSpaceLarge,
              ReusableButton(
                text: _currentPage < onboardingData.length - 1
                    ? AppStrings.next
                    : "Done",
                onPressed: () {
                  if (_currentPage < onboardingData.length - 1) {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
