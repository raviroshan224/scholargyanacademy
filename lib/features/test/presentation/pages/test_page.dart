import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/core.dart';
import '../../../explore/explore.dart';
import '../../models/mock_test_models.dart';
import '../../models/test_session_models.dart';
import '../../view_model/mock_test_view_model.dart';
import '../../view_model/test_session_view_model.dart';
import '../widgets/mock_test_list.dart';
import '../widgets/test_history.dart';
import 'detail_pages/quiz_page.dart';
import 'detail_pages/test_details.dart';
import 'detail_pages/select_course.dart';

final selectedTabIndexProvider = StateProvider<int>((Ref ref) => 0);

class TestPage extends ConsumerStatefulWidget {
  const TestPage({super.key});

  @override
  ConsumerState<TestPage> createState() => _TestPageState();
}

class _TestPageState extends ConsumerState<TestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(testSessionViewModelProvider.notifier).loadHistory();
      final mockTestState = ref.read(mockTestViewModelProvider);
      if (!mockTestState.loadingCourses && mockTestState.courses.isEmpty) {
        ref.read(mockTestViewModelProvider.notifier).loadCourses(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabTitles = ['Available Tests', 'Test History'];
    final tabIndex = ref.watch(selectedTabIndexProvider);
    final mockTestState = ref.watch(mockTestViewModelProvider);
    final mockTestNotifier = ref.read(mockTestViewModelProvider.notifier);
    final sessionState = ref.watch(testSessionViewModelProvider);
    final sessionNotifier = ref.read(testSessionViewModelProvider.notifier);

    final isLoadingMore = mockTestState.loadingTests &&
        mockTestState.tests.isNotEmpty &&
        !mockTestState.refreshing;
    final quickTest =
        mockTestState.tests.isNotEmpty ? mockTestState.tests.first : null;

    return Scaffold(
      appBar: CustomAppBar(title: 'Mock Tests'),
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(
              state: mockTestState,
              onSelectCourse: (courseId) {
                mockTestNotifier.selectCourse(courseId);
              },
              onManageCourses: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestSelectCourse(),
                  ),
                );
              },
              onQuickStart:
                  quickTest != null ? () => _startMockTest(quickTest) : null,
              quickTestTitle: quickTest?.title,
            ),
            AppSpacing.verticalSpaceMedium,
            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.gray200, width: 1),
                ),
              ),
              child: Row(
                children: tabTitles.map((title) {
                  final index = tabTitles.indexOf(title);
                  final isSelected = tabIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(selectedTabIndexProvider.notifier).state =
                            index;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: isSelected
                              ? Border(
                                  bottom: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                )
                              : null,
                        ),
                        child: CText(
                          title,
                          type: TextType.bodyMedium,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.gray600,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            AppSpacing.verticalSpaceMedium,
            Expanded(
              child: IndexedStack(
                index: tabIndex,
                children: [
                  MockTestListView(
                    tests: mockTestState.tests,
                    isLoading: mockTestState.loadingTests &&
                        mockTestState.tests.isEmpty,
                    isLoadingMore: isLoadingMore,
                    errorMessage: mockTestState.testsError?.message,
                    onRefresh: () => mockTestNotifier.refreshTests(),
                    onLoadMore: mockTestNotifier.loadNextPage,
                    onTestTap: (mockTest) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestDetailsPage(
                            initialTest: mockTest,
                          ),
                        ),
                      );
                    },
                    onStartTest: (mockTest) => _startMockTest(mockTest),
                  ),
                  TestHistory(
                    sessions: sessionState.history,
                    isLoading: sessionState.historyLoading,
                    errorMessage: sessionState.historyError?.message,
                    onRefresh: () => sessionNotifier.loadHistory(force: true),
                    onHistoryTap: (TestHistoryItem historyItem) async {
                      await sessionNotifier.loadSession(historyItem.sessionId);
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPage(
                            sessionId: historyItem.sessionId,
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMockTest(MockTest test) async {
    final scaffold = ScaffoldMessenger.of(context);
    final sessionNotifier = ref.read(testSessionViewModelProvider.notifier);

    if (test.canTakeTest) {
      final session = await sessionNotifier.startTest(test.id);
      if (!mounted) return;

      if (session == null) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Unable to start test. Please retry.')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(sessionId: session.sessionId),
        ),
      );
      return;
    }

    // Navigate to test details page for purchase
    // User will use the "Buy Test" button there
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestDetailsPage(
          initialTest: test,
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.state,
    required this.onSelectCourse,
    required this.onManageCourses,
    required this.onQuickStart,
    this.quickTestTitle,
  });

  final MockTestState state;
  final ValueChanged<String> onSelectCourse;
  final VoidCallback onManageCourses;
  final VoidCallback? onQuickStart;
  final String? quickTestTitle;

  @override
  Widget build(BuildContext context) {
    final courseItems = state.courses
        .where((course) => course.id.isNotEmpty)
        .map(
          (course) => DropdownMenuItem<String>(
            value: course.id,
            child: CText(
              course.courseTitle.isNotEmpty
                  ? course.courseTitle
                  : 'Course ${course.id}',
              type: TextType.bodyMedium,
              color: AppColors.black,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
    final selectedValue =
        courseItems.any((item) => item.value == state.selectedCourseId)
            ? state.selectedCourseId
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact course selector: inline label + small dropdown + manage button
        Row(
          children: [
            const CText(
              'Course:',
              type: TextType.labelMedium,
              color: AppColors.gray700,
            ),
            AppSpacing.horizontalSpaceSmall,
            Expanded(
              child: SizedBox(
                height: 40,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedValue,
                    isExpanded: true,
                    isDense: true,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: CText(
                        'Choose a course',
                        color: AppColors.gray500,
                        type: TextType.bodySmall,
                      ),
                    ),
                    items: courseItems,
                    onChanged: (value) {
                      if (value != null) onSelectCourse(value);
                    },
                    borderRadius: BorderRadius.circular(8),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            AppSpacing.horizontalSpaceSmall,
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: onManageCourses,
              icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
              tooltip: 'Manage courses',
            ),
          ],
        ),

        // Error/loading states (compact)
        if (state.loadingCourses)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(),
          ),
        if (courseItems.isEmpty && !state.loadingCourses)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: AppColors.gray500, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: CText(
                    'No courses available',
                    type: TextType.bodySmall,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        if (state.coursesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.failure, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: CText(
                    state.coursesError!.message,
                    type: TextType.bodySmall,
                    color: AppColors.failure,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
