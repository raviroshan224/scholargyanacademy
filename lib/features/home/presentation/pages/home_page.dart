import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:scholarsgyanacademy/features/home/presentation/pages/search_page.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../config/services/remote_services/api_endpoints.dart';
import '../../../../core/core.dart';
import '../../../courses/model/live_class_models.dart';
import '../../../courses/presentation/pages/upcoming_live_classes_page.dart';
import '../../../exams/presentation/pages/exam_detail_page.dart';
import '../../../exams/presentation/pages/exam_list_page.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../models/homepage_models.dart' as home_models;
import '../../view_model/homepage_view_model.dart';
import '../widgets/course_track_card.dart';
import '../widgets/grab_the_deal.dart';
import '../widgets/live_classes.dart';
import '../widgets/preferred_category_list.dart';
import '../widgets/recommended_course.dart';
import '../widgets/slider/home_slider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to convert LiveClassModel to LiveClass
  List<home_models.LiveClass> _convertToLiveClass(List<LiveClassModel> models) {
    return models
        .map(
          (model) => home_models.LiveClass(
            id: model.id,
            title: model.title,
            scheduledAt: model.startTime,
            thumbnailUrl: model.bannerImageUrl,
          ),
        )
        .toList();
  }

  // Reusable shimmer components for sections

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homepageViewModelProvider);
    final notifier = ref.read(homepageViewModelProvider.notifier);

    final profile = state.userProfile;
    final String? profilePhotoUrl = _normalizeUrl(profile?.photo);
    // Debug aid for image binding issues
    // ignore: avoid_print
    // print('HomePage: profilePhotoUrl=${profilePhotoUrl ?? 'null'}');
    final recommendedCourses = state.recommendedCourses
        .map(_mapCourseToCardData)
        .toList();

    // Debug log for Languages/Preferred Categories
    // debugPrint(
    //     'HomePage: preferredCategories count = ${state.preferredCategories.length}');
    // for (var cat in state.preferredCategories) {
    //   debugPrint('Language/Category: id=${cat.id}, name=${cat.categoryName}');
    // }

    final upcomingExam = state.upcomingExam;
    final topCategory = state.topCategoryWithCourses;

    final dateFormatter = DateFormat('MMM d, yyyy');
    final upcomingExamDate = upcomingExam?.examDate != null
        ? dateFormatter.format(upcomingExam!.examDate!.toLocal())
        : null;

    if (state.loading) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: _buildShimmerPlaceholder(),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: _buildNormalBody(
          state,
          notifier,
          recommendedCourses,
          upcomingExam,
          topCategory,
          profilePhotoUrl,
          profile,
        ),
      );
    }
  }

  Widget _buildShimmerPlaceholder() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 12.0,
            top: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 20, width: 150, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(height: 16, width: 200, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search bar
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              // Sliders
              Container(height: 150, color: Colors.white),
              const SizedBox(height: 16),
              // Recommended Courses
              Container(height: 20, width: 150, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 200, color: Colors.white),
              const SizedBox(height: 16),
              // Latest Ongoing Course
              Container(height: 20, width: 150, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 100, color: Colors.white),
              const SizedBox(height: 16),
              // Live Classes
              Container(height: 20, width: 100, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 140, color: Colors.white),
              const SizedBox(height: 16),
              // Upcoming Exams
              Container(height: 20, width: 120, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 150, color: Colors.white),
              const SizedBox(height: 16),
              // Languages
              Container(height: 20, width: 80, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 202, color: Colors.white),
              const SizedBox(height: 16),
              // Grab the Deals
              Container(height: 20, width: 120, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 200, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalBody(
    HomepageState state,
    HomepageViewModel notifier,
    List<CourseCardData> recommendedCourses,
    var upcomingExam,
    var topCategory,
    String? profilePhotoUrl,
    home_models.UserProfile? profile,
  ) {
    final dateFormatter = DateFormat('MMM d, yyyy');
    final upcomingExamDate = upcomingExam?.examDate != null
        ? dateFormatter.format(upcomingExam!.examDate!.toLocal())
        : null;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => notifier.getHomepageData(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 12.0,
                  top: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.error != null)
                      _ErrorBanner(
                        message: state.error!.message,
                        onRetry: () =>
                            notifier.getHomepageData(forceRefresh: true),
                      ),
                    // Compact header: avatar + greeting + subtitle + action
                    SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfilePage(),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: profilePhotoUrl != null
                                ? NetworkImage(profilePhotoUrl)
                                : AssetImage(AppAssets.loginBg)
                                      as ImageProvider,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (profile?.fullName != null)
                                CText(
                                  'Hey, ${profile!.fullName!.split(' ').first}',
                                  type: TextType.headlineSmall,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              AppSpacing.verticalSpaceTiny,
                              const CText(
                                'Find a course you are interested in',
                                type: TextType.bodySmall,
                                color: AppColors.gray600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalSpaceSmall,
                    // Search bar (navigates to SearchPage)
                    GestureDetector(
                      onTap: _navigateToSearch,
                      child: AbsorbPointer(
                        child: CustTextField(
                          borderRadius: 8,
                          hintText: 'Search courses or mock tests',
                          hintColor: AppColors.gray400,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgPicture.asset(AppAssets.searchIcon),
                          ),
                          controller: _searchController,
                        ),
                      ),
                    ),
                    AppSpacing.verticalSpaceSmall,
                    const HomeSliders(),
                    // Spacing handled inside HomeSliders when visible

                    // Recommended Courses
                    if (!state.hasData || recommendedCourses.isNotEmpty) ...[
                      TitleTextRow(
                        cardTitle: 'Recommended Courses',
                        showSubTitle: true,
                        onClick: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExplorePage(),
                            ),
                          );
                        },
                      ),
                      AppSpacing.verticalSpaceSmall,
                      if (!state.hasData)
                        _SectionShimmer.list(height: 200)
                      else
                        RecommendedCourse(
                          items: recommendedCourses,
                          isLoading: false,
                        ),
                      AppSpacing.verticalSpaceSmall,
                    ],

                    // Latest Ongoing Course
                    if (!state.hasData ||
                        state.latestOngoingCourse != null) ...[
                      TitleTextRow(
                        cardTitle: 'Latest Ongoing Course',
                        showSubTitle: false,
                      ),
                      AppSpacing.verticalSpaceSmall,
                      if (!state.hasData)
                        _SectionShimmer.card(height: 100)
                      else
                        CourseTrackCard(
                          course: state.latestOngoingCourse,
                          isLoading: false,
                        ),
                      AppSpacing.verticalSpaceMedium,
                    ],

                    // Upcoming Classes
                    if (!state.hasData ||
                        state.upcomingLiveClasses.isNotEmpty) ...[
                      TitleTextRow(
                        cardTitle: 'Upcoming Classes',
                        showSubTitle: true,
                        onClick: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UpcomingLiveClassesPage(),
                            ),
                          );
                        },
                      ),
                      AppSpacing.verticalSpaceSmall,
                      if (!state.hasData)
                        _SectionShimmer.list(height: 140)
                      else
                        LiveClasses(
                          liveClasses: _convertToLiveClass(
                            state.upcomingLiveClasses,
                          ),
                          isLoading: state.isUpcomingLiveClassesLoading,
                          isUpcoming: true,
                        ),
                      AppSpacing.verticalSpaceMedium,
                    ],

                    // Live Classes
                    if (!state.hasData || state.liveClasses.isNotEmpty) ...[
                      AppSpacing.verticalSpaceMedium,
                      TitleTextRow(
                        cardTitle: 'Live Classes',
                        showSubTitle: false,
                      ),
                      AppSpacing.verticalSpaceSmall,
                      if (!state.hasData)
                        _SectionShimmer.list(height: 140)
                      else
                        LiveClasses(
                          liveClasses: state.liveClasses,
                          isLoading: false,
                        ),
                    ],

                    // Upcoming Exams
                    if (!state.hasData || upcomingExam != null) ...[
                      AppSpacing.verticalSpaceMedium,
                      TitleTextRow(
                        cardTitle: 'Upcoming Exams',
                        showSubTitle: true,
                        onClick: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExamListPage(),
                            ),
                          );
                        },
                      ),
                      AppSpacing.verticalSpaceSmall,
                      if (!state.hasData)
                        _SectionShimmer.card(height: 150)
                      else
                        InkWell(
                          onTap: () {
                            final examId = upcomingExam!.id;
                            if (examId == null) {
                              AppMethods.showCustomSnackBar(
                                context: context,
                                message: 'Exam information is incomplete.',
                                isError: true,
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExamDetailPage(examId: examId),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Exam Image
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 2.5,
                                    child: CustomCachedNetworkImage(
                                      imageUrl:
                                          upcomingExam.examImageUrl ??
                                          AppAssets.dummyNetImg,
                                      fitStatus: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Exam Info
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CText(
                                        upcomingExam.title ?? 'Upcoming exam',
                                        type: TextType.bodyMedium,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.black,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      CText(
                                        upcomingExamDate != null
                                            ? 'Exam Date: $upcomingExamDate'
                                            : upcomingExam.daysUntilExam != null
                                            ? '${upcomingExam.daysUntilExam} days remaining'
                                            : 'Stay tuned for the exam schedule.',
                                        type: TextType.bodySmall,
                                        color: AppColors.gray600,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],

                    // Languages (Preferred Categories)
                    if (!state.hasData ||
                        state.preferredCategories.isNotEmpty) ...[
                      AppSpacing.verticalSpaceMedium,
                      TitleTextRow(
                        cardTitle: 'Preferred Categories',
                        showSubTitle: false,
                      ),
                      AppSpacing.verticalSpaceSmall,
                      if (state.updatingCategory)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: LinearProgressIndicator(),
                        ),
                      if (state.updateError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: CText(
                            state.updateError!.message,
                            type: TextType.bodySmall,
                            color: AppColors.failure,
                          ),
                        ),
                      if (!state.hasData)
                        _SectionShimmer.list(height: 120)
                      else
                        PreferredCategoryList(
                          categories: state.preferredCategories,
                          isLoading: false,
                        ),
                    ],

                    // Grab the Deals
                    if (!state.hasData ||
                        (topCategory != null &&
                            topCategory.courses.isNotEmpty)) ...[
                      AppSpacing.verticalSpaceMedium,
                      TitleTextRow(
                        cardTitle: 'Grab the Deals',
                        showSubTitle: false,
                      ),
                      AppSpacing.verticalSpaceSmall,
                      if (!state.hasData)
                        _SectionShimmer.card(height: 200)
                      else
                        GrabTheDealList(
                          topCategory: topCategory,
                          isLoading: false,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Search handled on separate page
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.failureWithOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.failureWithOpacity(0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CText(
              message,
              type: TextType.bodySmall,
              color: AppColors.failure,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: CText(
              'Retry',
              type: TextType.bodySmall,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedExamsHorizontal extends StatelessWidget {
  const _RecommendedExamsHorizontal({
    required this.exams,
    this.isLoading = false,
  });

  final List<home_models.Exam> exams;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    if (exams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: CText(
          'No upcoming exams or live classes at the moment.',
          type: TextType.bodySmall,
          color: AppColors.gray500,
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: exams.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final e = exams[index];
          return SizedBox(
            width: 220,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomCachedNetworkImage(
                        imageUrl: e.examImageUrl ?? AppAssets.dummyNetImg,
                        fitStatus: BoxFit.cover,
                      ),
                    ),
                    AppSpacing.verticalSpaceSmall,
                    GestureDetector(
                      onTap: () {
                        final examId = e.id;
                        if (examId == null) {
                          AppMethods.showCustomSnackBar(
                            context: context,
                            message: 'Exam information is incomplete.',
                            isError: true,
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamDetailPage(examId: examId),
                          ),
                        );
                      },
                      child: CText(
                        e.title ?? 'Exam',
                        type: TextType.bodySmall,
                        color: AppColors.black,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Reusable shimmer components for sections
class _SectionShimmer {
  const _SectionShimmer._();

  static Widget list({required double height}) => Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  static Widget card({required double height}) => Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

CourseCardData _mapCourseToCardData(home_models.Course course) {
  // Use courseIconUrl if available, else courseImageUrl, then fallback
  final imageUrl =
      (course.courseIconUrl != null && course.courseIconUrl!.isNotEmpty)
      ? course.courseIconUrl
      : course.courseImageUrl;

  return CourseCardData(
    title: course.courseTitle ?? 'Course',
    subtitle: _formatCourseSubtitle(course),
    imageUrl: imageUrl ?? AppAssets.errorImage,
    courseId: course.id,
    isSaved: course.isSaved ?? false,
    enrollmentCost: course.enrollmentCost,
    discountedPrice: course.discountedPrice,
    hasOffer: course.hasOffer,
    durationHours: course.durationHours,
    validityDays: course.validityDays,
  );
}

String _formatCourseSubtitle(home_models.Course course) {
  final parts = <String>[];
  if (course.durationHours != null && course.durationHours! > 0) {
    parts.add('${course.durationHours}h content');
  }
  if (course.validityDays != null && course.validityDays! > 0) {
    parts.add('${course.validityDays}d access');
  }
  if (parts.isEmpty && (course.categoryName?.isNotEmpty ?? false)) {
    parts.add(course.categoryName!);
  }
  return parts.isEmpty ? 'View details' : parts.join(' • ');
}

// Returns absolute URL if already absolute, else null to force fallback/skip
String? _normalizeUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return trimmed;
  }
  // If the API returns only a filename, prefix with the configured image base URL
  // and return the full absolute URL.
  // e.g., API: "3bcac9f43e817d2ece2a6.jpg" -> https://olp-uploads.s3.us-east-1.amazonaws.com/3bcac9f43e817d2ece2a6.jpg
  final candidate = ApiEndPoints.imageBaseUrl + trimmed;
  return candidate;
}
