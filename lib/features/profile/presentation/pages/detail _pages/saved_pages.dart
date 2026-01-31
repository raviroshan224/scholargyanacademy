import 'package:flutter/material.dart';

import '../../../../../core/constant/app_colors.dart';
import '../../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../courses/presentation/widgets/saved_courses.dart';

class SavedPages extends StatelessWidget {
  const SavedPages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: "Saved Courses"),
      body: const SavedCoursesWidget(),
    );
  }
}
