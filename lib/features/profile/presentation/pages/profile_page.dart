import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/config/services/navigation_service.dart';

import '../../../../core/core.dart';
import '../../../auth/view_model/auth_state.dart';
import '../../../auth/view_model/providers/auth_providers.dart';
import '../../../before_auth/presentation/pages/course_selection.dart';
import '../../../exams/presentation/pages/exam_list_page.dart';
import '../../../test/test.dart';
import '../../profile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _hasRequestedProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeFetchProfile();
    });
  }

  void _maybeFetchProfile() {
    if (_hasRequestedProfile) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      ref.read(authNotifierProvider.notifier).getMe();
    }
    _hasRequestedProfile = true;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.error &&
          next.error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          AppMethods.showCustomSnackBar(
            context: context,
            message: next.error!,
            isError: true,
          );
        });
      }
    });
    final navService = ref.read(navigationServiceProvider);

    final isLoading = authState.status == AuthStatus.loading;
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: 'Profile'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            ProfileInfo(
              user: user,
              isLoading: isLoading,
              onEdit: () {
                if (!isLoading) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditPage()),
                  );
                }
              },
            ),
            AppSpacing.verticalSpaceLarge,
            ProfileTextRow(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExamListPage()),
                );
              },
              icon: AppAssets.profileCoursesIcon,
              cardTitle: 'Exam Lists',
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: ProfileTextRow(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SavedPages()),
                  );
                },
                icon: AppAssets.savedIcon,
                cardTitle: 'Saved Courses',
              ),
            ),
            ProfileTextRow(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TestPage()),
                );
              },
              icon: AppAssets.testIcon,
              cardTitle: 'Mock Tests',
            ),
            ProfileTextRow(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseSelection(fromLogin: false),
                  ),
                );
              },
              icon: AppAssets.testIcon,
              cardTitle: 'Preferred Categories',
            ),
            AppSpacing.verticalSpaceSmall,
            const Divider(thickness: 1),
            AppSpacing.verticalSpaceAverage,
            CText('General Settings', type: TextType.headlineSmall),
            AppSpacing.verticalSpaceSmall,
            ProfileTextRow(
              onPressed: () {
                if (isLoading) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditPage()),
                );
              },
              icon: AppAssets.userIcon,
              cardTitle: 'My Profile',
              isLoading: isLoading,
            ),
            ProfileTextRow(
              onPressed: () async {
                if (isLoading) return;

                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const CText(
                        'Confirm Logout',
                        type: TextType.headlineSmall,
                      ),
                      content: const CText(
                        'Are you sure you want to logout?',
                        type: TextType.bodyMedium,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const CText(
                            'Cancel',
                            type: TextType.bodyMedium,
                            color: AppColors.gray600,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.failure,
                          ),
                          child: const CText(
                            'Logout',
                            type: TextType.bodyMedium,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    );
                  },
                );

                // Only logout if user confirmed
                if (shouldLogout == true) {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (!mounted) return;
                  navService.navigateToLogin(
                    errorMessage: 'You have been logged out.',
                  );
                }
              },
              icon: AppAssets.logoutIcon,
              cardTitle: 'Logout',
              isLoading: isLoading,
            ),
            AppSpacing.verticalSpaceSmall,
            const Divider(thickness: 1),
            AppSpacing.verticalSpaceAverage,
            CText('About Us', type: TextType.headlineSmall),
            AppSpacing.verticalSpaceSmall,
            ProfileTextRow(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutUsPage()),
                );
              },
              icon: AppAssets.aboutUSIcon,
              cardTitle: 'About Us',
            ),
            ProfileTextRow(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TermsAndConditions()),
                );
              },
              icon: AppAssets.termsIcon,
              cardTitle: 'Terms & Conditions',
            ),
            ProfileTextRow(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQPage()),
                );
              },
              icon: AppAssets.faqIcon,
              cardTitle: 'FAQs',
            ),
            ProfileTextRow(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SupportPage()),
                );
              },
              icon: AppAssets.helpSupportIcon,
              cardTitle: 'Help & support',
            ),
            ProfileTextRow(
              onPressed: () {},
              icon: AppAssets.privacyPolicyIcon,
              cardTitle: 'Privacy Policy',
            ),
          ],
        ),
      ),
    );
  }
}
