import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../../courses/presentation/pages/enrolled_course_details_page.dart';
import '../../../test/models/mock_test_models.dart';
import '../../../test/presentation/pages/detail_pages/test_details.dart';
import '../../models/search_models.dart';
import '../../view_model/home_search_view_model.dart';
// Note: Course enrollment info is not returned by SearchCourse model,
// so navigate to EnrolledCourseDetailsPage which handles course details/enrollment.

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    // Clear search state when leaving the page
    ref.read(homeSearchViewModelProvider.notifier).clearSearch();
    super.dispose();
  }

  void _onTextChanged() {
    ref
        .read(homeSearchViewModelProvider.notifier)
        .onSearchChanged(_controller.text);
  }

  void _clear() {
    _controller.clear();
    ref.read(homeSearchViewModelProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeSearchViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.gray800,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: CustTextField(
          controller: _controller,
          focusNode: _focusNode,
          borderRadius: 8,
          hintText: 'Search courses or mock tests',
          hintColor: AppColors.gray400,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.search, color: AppColors.gray600),
          ),
          suffixIcon: state.query.isNotEmpty
              ? IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.close, color: AppColors.gray600),
                )
              : null,
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(HomeSearchState state) {
    // Initial / hint state - show prompt message
    if (state.query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 64, color: AppColors.gray300),
              AppSpacing.verticalSpaceMedium,
              CText(
                'Search for courses or mock tests',
                type: TextType.bodyMedium,
                color: AppColors.gray600,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Query too short - show minimum length hint
    if (state.query.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CText(
            'Type at least 2 characters to search',
            type: TextType.bodyMedium,
            color: AppColors.gray500,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.failure),
              AppSpacing.verticalSpaceMedium,
              CText(state.error!.message,
                  type: TextType.bodyMedium,
                  color: AppColors.gray600,
                  textAlign: TextAlign.center),
              AppSpacing.verticalSpaceSmall,
              ReusableButton(
                  text: 'Retry',
                  onPressed: () =>
                      ref.read(homeSearchViewModelProvider.notifier).retrySearch()),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: AppColors.gray400),
              AppSpacing.verticalSpaceMedium,
              CText('No courses or mock tests found',
                  type: TextType.bodyMedium,
                  color: AppColors.gray600,
                  textAlign: TextAlign.center),
              AppSpacing.verticalSpaceSmall,
              CText('Try a different search term',
                  type: TextType.bodySmall,
                  color: AppColors.gray500,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final courses = state.courses;
    final mockTests = state.mockTests;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (courses.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                CText('Courses (${courses.length})',
                    type: TextType.titleSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black),
              ],
            ),
          ),
          ...courses.map((c) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _CourseSearchCard(
                    course: c, onTap: () => _navigateToCourse(context, c)),
              )),
          AppSpacing.verticalSpaceMedium,
        ],
        if (mockTests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.quiz_outlined,
                    size: 20, color: AppColors.secondary),
                const SizedBox(width: 8),
                CText('Mock Tests (${mockTests.length})',
                    type: TextType.titleSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black),
              ],
            ),
          ),
          ...mockTests.map((t) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _MockTestSearchCard(
                    mockTest: t, onTap: () => _navigateToMockTest(context, t)),
              )),
        ],
      ],
    );
  }

  void _navigateToCourse(BuildContext context, SearchCourse course) {
    if (course.id == null || course.id!.isEmpty) {
      AppMethods.showCustomSnackBar(
          context: context,
          message: 'Course information is incomplete.',
          isError: true);
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EnrolledCourseDetailsPage(courseId: course.id!)));
  }

  void _navigateToMockTest(BuildContext context, SearchMockTest test) {
    if (test.id == null || test.id!.isEmpty) {
      AppMethods.showCustomSnackBar(
          context: context,
          message: 'Mock test information is incomplete.',
          isError: true);
      return;
    }
    final mockTest = MockTest(
        id: test.id!,
        courseId: test.courseId ?? '',
        title: test.title,
        description: test.description,
        cost: test.cost,
        durationMinutes: test.durationMinutes);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TestDetailsPage(initialTest: mockTest)));
  }
}

// Reuse card widgets from overlay file
class _CourseSearchCard extends StatelessWidget {
  const _CourseSearchCard({required this.course, required this.onTap});

  final SearchCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomCachedNetworkImage(
                    imageUrl: course.courseImageUrl ?? AppAssets.dummyNetImg,
                    size: const Size(96, 64),
                    fitStatus: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CText(course.courseTitle ?? 'Course',
                        type: TextType.bodyMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    if (course.categoryName != null)
                      CText(course.categoryName!,
                          type: TextType.bodySmall, color: AppColors.gray500),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (course.enrollmentCost == 0) ...[
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: const CText('FREE',
                                  type: TextType.bodySmall,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success)),
                        ] else if (course.hasOffer == true &&
                            course.enrollmentCost != null &&
                            course.discountedPrice != null &&
                            course.enrollmentCost! >
                                course.discountedPrice!) ...[
                          // Discounted Price
                          CText(
                            'Rs. ${NumberFormat.decimalPattern().format(course.discountedPrice)}',
                            type: TextType.bodySmall,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          const SizedBox(width: 6),
                          // Original Price (Strikethrough)
                          Text(
                            'Rs. ${NumberFormat.decimalPattern().format(course.enrollmentCost)}',
                            style: const TextStyle(
                              fontSize: 11.0,
                              color: AppColors.gray500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ] else if (course.enrollmentCost != null) ...[
                          CText('Rs. ${course.enrollmentCost}',
                              type: TextType.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ],
                        const Spacer(),
                        if (course.durationHours != null)
                          Row(children: [
                            Icon(Icons.access_time,
                                size: 12, color: AppColors.gray500),
                            const SizedBox(width: 4),
                            CText('${course.durationHours}h',
                                type: TextType.bodySmall,
                                color: AppColors.gray500)
                          ])
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _MockTestSearchCard extends StatelessWidget {
  const _MockTestSearchCard({required this.mockTest, required this.onTap});

  final SearchMockTest mockTest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.quiz_outlined,
                  color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CText(mockTest.title ?? 'Mock Test',
                      type: TextType.bodyMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (mockTest.description != null) ...[
                    const SizedBox(height: 2),
                    CText(mockTest.description!,
                        type: TextType.bodySmall,
                        color: AppColors.gray500,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    if (mockTest.cost != null && mockTest.cost! > 0) ...[
                      CText('Rs. ${mockTest.cost!.toStringAsFixed(0)}',
                          type: TextType.bodySmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                      const SizedBox(width: 12)
                    ] else ...[
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)),
                          child: const CText('FREE',
                              type: TextType.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success)),
                      const SizedBox(width: 12)
                    ],
                    if (mockTest.durationMinutes != null)
                      Row(children: [
                        Icon(Icons.access_time,
                            size: 12, color: AppColors.gray500),
                        const SizedBox(width: 2),
                        CText('${mockTest.durationMinutes} min',
                            type: TextType.bodySmall, color: AppColors.gray500)
                      ])
                  ]),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
