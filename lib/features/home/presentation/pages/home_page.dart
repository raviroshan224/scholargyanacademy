import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../../exams/presentation/pages/exam_detail_page.dart';
import '../../../exams/presentation/pages/exam_list_page.dart';
import '../../../explore/presentation/pages/explore_page.dart';
import '../../models/homepage_models.dart' as home_models;
import '../../view_model/homepage_view_model.dart';
import '../widgets/course_track_card.dart';
import '../widgets/grab_the_deal.dart';
import '../widgets/live_classes.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homepageViewModelProvider);
    final notifier = ref.read(homepageViewModelProvider.notifier);

    final profile = state.userProfile;
    final recommendedCourses =
        state.recommendedCourses.map(_mapCourseToCardData).toList();
    final preferredCategories =
        state.preferredCategories.map(_mapCategoryToCardData).toList();
    final upcomingExam = state.upcomingExam;
    final topCategory = state.topCategoryWithCourses;

    final dateFormatter = DateFormat('MMM d, yyyy');
    final upcomingExamDate = upcomingExam?.examDate != null
        ? dateFormatter.format(upcomingExam!.examDate!.toLocal())
        : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        // title: profile?.fullName ?? AppStrings.userName,
        leadingIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: (profile?.photo?.isNotEmpty ?? false)
                ? NetworkImage(profile!.photo!)
                : AssetImage(AppAssets.loginBg) as ImageProvider,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.getHomepageData(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.error != null)
                  _ErrorBanner(
                    message: state.error!.message,
                    onRetry: () => notifier.getHomepageData(forceRefresh: true),
                  ),
                // Compact header: avatar + greeting + subtitle + action
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: (profile?.photo?.isNotEmpty ?? false)
                          ? NetworkImage(profile!.photo!)
                          : AssetImage(AppAssets.loginBg) as ImageProvider,
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
                    IconButton(
                      onPressed: () {
                        // Placeholder action: open profile or settings
                      },
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSpaceMedium,

                // Search bar
                CustTextField(
                  borderRadius: 8,
                  hintText: 'Search Here',
                  hintColor: AppColors.gray400,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(AppAssets.searchIcon),
                  ),
                  controller: _searchController,
                  validator: FieldValidators.validateFullName,
                ),
                AppSpacing.verticalSpaceMedium,
                const HomeSliders(),
                AppSpacing.verticalSpaceMedium,

                // Recommended Courses
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
                RecommendedCourse(
                  items: recommendedCourses,
                  isLoading: state.loading && recommendedCourses.isEmpty,
                ),

                // Latest Ongoing Course
                AppSpacing.verticalSpaceMedium,
                TitleTextRow(
                  cardTitle: 'Latest Ongoing Course',
                  showSubTitle: false,
                ),
                AppSpacing.verticalSpaceSmall,

                CourseTrackCard(
                  course: state.latestOngoingCourse,
                  isLoading: state.loading && state.latestOngoingCourse == null,
                ),

                // Live Classes
                AppSpacing.verticalSpaceMedium,
                TitleTextRow(
                  cardTitle: 'Live Classes',
                  showSubTitle: false,
                ),
                AppSpacing.verticalSpaceSmall,

                LiveClasses(
                  liveClasses: state.liveClasses,
                  isLoading: state.loading && state.liveClasses.isEmpty,
                ),

                // Upcoming Exams
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
                if (upcomingExam != null)
                  InkWell(
                    onTap: () {
                      final examId = upcomingExam.id;
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
                                imageUrl: upcomingExam.examImageUrl ??
                                    AppAssets.dummyNetImg,
                                fitStatus: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Exam Info
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const CText(
                      'We will notify you when new exams are available.',
                      type: TextType.bodySmall,
                      color: AppColors.gray600,
                    ),
                  ),

                // Languages (Preferred Categories)
                AppSpacing.verticalSpaceMedium,
                TitleTextRow(
                  cardTitle: 'Languages',
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
                RecommendedCourse(
                  cardHeight: 202,
                  items: preferredCategories,
                  isLoading: state.loading && preferredCategories.isEmpty,
                  onItemTap: (card) {
                    if (card.categoryId != null && !state.updatingCategory) {
                      notifier.updateLatestCategory(card.categoryId!);
                    }
                  },
                  emptyLabel:
                      'Add favorite categories to personalize your homepage.',
                ),

                // Grab the Deals
                AppSpacing.verticalSpaceMedium,
                TitleTextRow(
                  cardTitle: 'Grab the Deals',
                  showSubTitle: false,
                ),
                AppSpacing.verticalSpaceSmall,

                GrabTheDealList(
                  topCategory: topCategory,
                  isLoading: state.loading && topCategory == null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

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
          height: 100, child: Center(child: CircularProgressIndicator()));
    if (exams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: CText('No upcoming exams or live classes at the moment.',
            type: TextType.bodySmall, color: AppColors.gray500),
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
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomCachedNetworkImage(
                          imageUrl: e.examImageUrl ?? AppAssets.dummyNetImg,
                          fitStatus: BoxFit.cover),
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
                      child: CText(e.title ?? 'Exam',
                          type: TextType.bodySmall,
                          color: AppColors.black,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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

CourseCardData _mapCourseToCardData(home_models.Course course) {
  return CourseCardData(
    title: course.courseTitle ?? 'Course',
    subtitle: _formatCourseSubtitle(course),
    imageUrl: course.courseImageUrl ?? AppAssets.errorImage,
    courseId: course.id,
    isSaved: course.isSaved ?? false,
    enrollmentCost: course.enrollmentCost,
    durationHours: course.durationHours,
    validityDays: course.validityDays,
  );
}

CourseCardData _mapCategoryToCardData(home_models.Category category) {
  return CourseCardData(
    title: category.categoryName ?? 'Category',
    subtitle: 'Tap to personalize your feed',
    imageUrl: category.categoryImageUrl ?? AppAssets.errorImage,
    categoryId: category.id,
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
