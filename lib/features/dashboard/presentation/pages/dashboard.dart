import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/core.dart';
import '../../../courses/courses.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import '../../../home/home.dart';
import '../../../profile/profile.dart';
import '../../../test/test.dart';
import '../../provider/nav_provider.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    return Scaffold(
      bottomNavigationBar: Card(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 10,
        child: BottomNavigationBar(
          selectedIconTheme: const IconThemeData(
            color: AppColors.primary,
          ),
          unselectedIconTheme: const IconThemeData(color: AppColors.gray700),
          selectedLabelStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(color: AppColors.gray700),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.gray700,
          currentIndex: navigationState.selectedIndex,
          onTap: (index) {
            ref.read(navigationProvider.notifier).navigate(index);
          },
          items: [
            _buildBottomNavigationBarItem(
              icon: AppAssets.homeIcon,
              label: 'Home',
              isSelected: navigationState.selectedIndex == 0,
            ),
            _buildBottomNavigationBarItem(
              icon: AppAssets.exploreIcon,
              label: 'Explore',
              isSelected: navigationState.selectedIndex == 1,
            ),
            _buildBottomNavigationBarItem(
              icon: AppAssets.coursesIcon,
              label: 'Courses',
              isSelected: navigationState.selectedIndex == 2,
            ),
            _buildBottomNavigationBarItem(
              icon: AppAssets.testIcon,
              label: 'Test',
              isSelected: navigationState.selectedIndex == 3,
            ),
            _buildBottomNavigationBarItem(
              icon: AppAssets.profileIcon,
              label: 'Profile',
              isSelected: navigationState.selectedIndex == 4,
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: navigationState.selectedIndex,
        children: [
          HomePage(),
          ExplorePage(),
          CoursePage(),
          TestPage(),
          ProfilePage(),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required String icon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: Column(
        children: [
          if (isSelected)
            Transform.scale(
              scale: 1.1, // Scale up the selected icon
              child: SvgPicture.asset(
                icon,
                color: AppColors.primary,
              ),
            )
          else
            SvgPicture.asset(
              icon,
              height: 20,
            ),
        ],
      ),
      label: label,
    );
  }
}
