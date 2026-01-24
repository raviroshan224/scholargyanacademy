import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/features/auth/auth.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';

import '../core/core.dart';
import '../features/before_auth/presentation/pages/course_selection.dart';
import '../features/before_auth/presentation/pages/onboard_page.dart';
import '../features/dashboard/presentation/pages/dashboard.dart';
import 'local_db/hive/hive_data_source.dart';
import 'local_db/hive/hive_provider.dart';

class AppInitializerScreen extends ConsumerStatefulWidget {
  const AppInitializerScreen({super.key});

  @override
  _AppInitializerScreenState createState() => _AppInitializerScreenState();
}

class _AppInitializerScreenState extends ConsumerState<AppInitializerScreen> {
  @override
  void initState() {
    super.initState();
    _showSplashScreen();
  }

  void _showSplashScreen() {
    // Show splash screen for 2 seconds before initialization
    Future.delayed(const Duration(milliseconds: 2000), () {
      _initializeAndNavigate();
    });
  }

  Future<void> _initializeAndNavigate() async {
    final HiveDataSource hive = ref.read(hiveDataSourceProvider);

    try {
      // Check onboarding status first
      final isFirstInstall = await hive.isFirstInstalled();
      if (isFirstInstall) {
        log('First install detected, navigating to onboarding');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnBoardingPage()),
        );
        await hive.updateFirstInstalled(false);
        return;
      }

      // Read token from Hive directly
      final accessToken = await hive.getAccessToken();
      log("Access token Check: $accessToken");
      log("Access token Length: ${accessToken.length}");

      if (accessToken.isNotEmpty && accessToken.length > 50) {
        log('User is logged in, fetching profile...');

        // Fetch user profile to check personalization status
        await ref.read(authNotifierProvider.notifier).getMe();

        // Wait for state to update
        await Future.delayed(const Duration(milliseconds: 100));

        final authState = ref.read(authNotifierProvider);
        final hasSelectedCategories =
            authState.user?.hasSelectedCategories ?? false;

        log('Has selected categories: $hasSelectedCategories');

        // Navigate based on personalization status
        final Widget destination = hasSelectedCategories
            ? Dashboard()
            : CourseSelection(
                userName: authState.user?.fullName ?? authState.user?.email,
              );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      } else {
        log('User not logged in or invalid token, navigating to onboarding');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnBoardingPage()),
        );
      }
    } catch (e) {
      log('Error in initialization: $e');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          AppAssets.appLogo,
          height: 143,
          width: 173,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
