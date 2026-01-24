import 'package:flutter/material.dart';
import 'package:scholarsgyanacademy/core/core.dart';
import 'package:scholarsgyanacademy/features/courses/presentation/widgets/saved_courses.dart';

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
