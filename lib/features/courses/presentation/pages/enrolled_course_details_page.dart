import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';

import '../../../../core/core.dart';
import '../../../explore/explore.dart';
import '../../courses.dart';
import '../../model/enrollment_models.dart';
import '../../service/course_service.dart';
import '../../view_model/course_view_model.dart';
import '../widgets/enroll_with_esewa_button.dart';

class EnrolledCourseDetailsPage extends ConsumerStatefulWidget {
  final String courseId;
  final int initialTabIndex;
  final EnrollmentModel? enrollment;

  const EnrolledCourseDetailsPage({
    super.key,
    required this.courseId,
    this.initialTabIndex = 0,
    this.enrollment,
  });

  @override
  ConsumerState<EnrolledCourseDetailsPage> createState() =>
      _EnrolledCourseDetailsPageState();
}

class _EnrolledCourseDetailsPageState
    extends ConsumerState<EnrolledCourseDetailsPage>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabTitles = <String>[
    'Syllabus',
    'Materials',
    'Lectures',
    'Live Classes',
    'Mock Tests',
    'Lecturers',
  ];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final safeIndex = widget.initialTabIndex.clamp(0, _tabTitles.length - 1);
    _tabController = TabController(
      length: _tabTitles.length,
      vsync: this,
      initialIndex: safeIndex,
    );
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      setState(() {});
      _handleTabSelection(_tabController.index);
    });
    // Only fetch if details for this course are not already present
    final currentState = ref.read(coursesViewModelProvider);
    final alreadyLoadedId = currentState.detailsCourseId;
    if (alreadyLoadedId != widget.courseId) {
      // use microtask to avoid calling provider synchronously during init
      Future.microtask(() {
        ref.read(coursesViewModelProvider.notifier).getDetails(widget.courseId);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safe place to listen to provider changes (inside build)
    ref.listen(coursesViewModelProvider, (previous, next) {
      final details = next.details;
      final error = next.detailsError;
      if (details != null) {
        final course = details['course'] as Map<String, dynamic>?;
        if (course != null && mounted) {
          debugPrint(
            'Course details loaded: ${course['courseTitle']} (id: ${course['id'] ?? widget.courseId})',
          );
        }
        final wasLoaded = previous?.details != null;
        if (!wasLoaded && next.isEnrolled && mounted) {
          Future.microtask(() => _handleTabSelection(_tabController.index));
        }
      }
      if (error != null && mounted) {
        debugPrint('Failed to load course details: ${error.message}');
      }
    });

    final state = ref.watch(coursesViewModelProvider);
    final details = state.details;
    final course = details != null
        ? details['course'] as Map<String, dynamic>?
        : null;
    final isLoading = state.loadingDetails && details == null;

    void _handleFreeEnrollment() async {
      setState(() {
        // We can use a local loading state variable for the button if needed,
        // or just rely on the modal blocking interaction.
        // For simplicity, we can show a loading dialog or just set a local state.
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final courseService = ref.read(courseServiceProvider);
      final result = await courseService.enrollFreeCourse(widget.courseId);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enrollment failed: ${failure.message}'),
              backgroundColor: AppColors.failure,
            ),
          );
        },
        (_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 64,
                  ),
                  AppSpacing.verticalSpaceMedium,
                  const CText(
                    'You’ve successfully enrolled in this course',
                    type: TextType.titleMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  AppSpacing.verticalSpaceMedium,
                  ReusableButton(
                    text: 'Done',
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      // Refresh details to update state to "enrolled"
                      ref
                          .read(coursesViewModelProvider.notifier)
                          .getDetails(widget.courseId);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final error = state.detailsError;
    final tags = course?['tags'] is List
        ? (course!['tags'] as List)
              .whereType<String>()
              .map((e) => e.trim())
              .where((element) => element.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    Widget buildHeader(Map<String, dynamic>? course) {
      // Handle null course data - show loading placeholder
      if (course == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 200,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  AppSpacing.verticalSpaceMedium,
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      final title = course['courseTitle']?.toString() ?? 'Course';

      final description = course['courseDescription']?.toString() ?? '';

      // Prioritize courseIconUrl for detail page, fallback to courseImageUrl, then placeholder
      final courseIconUrl = course['courseIconUrl']?.toString();
      final coverImageUrl = course['courseIconUrl']?.toString();
      final courseImageUrl = course['courseImageUrl']?.toString();
      final imageUrl = (courseImageUrl != null && courseImageUrl.isNotEmpty)
          ? courseImageUrl
          // : (courseImageUrl != null && courseImageUrl.isNotEmpty)
          //     ? courseImageUrl
          : AppAssets.dummyNetImg;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Stack(
              children: [
                CustomCachedNetworkImage(
                  imageUrl: imageUrl,
                  size: Size(double.infinity, 200),
                ),
                // Gradient overlay for better text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CText(title, maxLines: 7, type: TextType.headlineLarge),
                AppSpacing.verticalSpaceSmall,
                // Duration with clock icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CText(
                      'Duration: ${course?['durationHours'] != null && course!['durationHours'] != 0 ? course!['durationHours'] : 'N/A'} Hours',
                      type: TextType.bodyMedium,
                      color: AppColors.gray600,
                    ),
                    CText(
                      'Expires In: ${course?['validityDays'] != null && course!['validityDays'] != 0 ? course!['validityDays'] : 'N/A'} Days',
                      type: TextType.bodyMedium,
                      color: AppColors.gray600,
                    ),
                  ],
                ),
                AppSpacing.verticalSpaceMedium,
                ReadMoreText(
                  description,
                  trimLines: 10,
                  trimMode: TrimMode.Line,
                  trimCollapsedText: 'See More...',
                  trimExpandedText: '...Read Less',
                  colorClickableText: AppColors.gray400,
                  style: const TextStyle(fontSize: 13.0, height: 1.5),
                  moreStyle: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                  lessStyle: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    EnrollmentModel? resolveEnrollment() {
      if (widget.enrollment != null) {
        return widget.enrollment;
      }
      final detailsEnrollment =
          details?['enrollmentDetails'] ?? details?['enrollment'];
      if (detailsEnrollment is Map<String, dynamic>) {
        final map = Map<String, dynamic>.from(detailsEnrollment);
        final courseMap = course ?? map['course'];
        if (courseMap is Map<String, dynamic>) {
          map['course'] = courseMap;
          map.putIfAbsent('courseId', () => courseMap['id'] ?? widget.courseId);
        } else {
          map.putIfAbsent('courseId', () => widget.courseId);
        }
        map.putIfAbsent('id', () => map['id'] ?? map['_id'] ?? widget.courseId);
        return EnrollmentModel.fromJson(map);
      }
      return null;
    }

    Widget buildEnrollmentOverview(EnrollmentModel? data) {
      if (data == null) return const SizedBox.shrink();
      final progress = (data.progress?.progressPercentage ?? 0)
          .clamp(0, 100)
          .toDouble();
      final progressValue = progress / 100;
      final completed = data.progress?.completedLecturesCount ?? 0;
      final total = data.progress?.totalLectures ?? 0;
      final progressLabel = total > 0
          ? '$completed of $total lectures completed'
          : 'Start learning to unlock progress insights';
      final expiry = data.expiryDate != null
          ? DateTime.tryParse(data.expiryDate!)
          : null;
      final certificateIssued = data.certificate?.issued ?? false;
      final status = (data.status ?? 'active').toLowerCase();
      final enrolledOn = data.enrollmentDate != null
          ? DateTime.tryParse(data.enrollmentDate!)
          : null;

      Widget statusChip() {
        late final Color fill;
        late final Color textColor;
        late final String label;
        switch (status) {
          case 'completed':
            fill = AppColors.success.withOpacity(0.12);
            textColor = AppColors.success;
            label = 'Completed';
            break;
          case 'expired':
          case 'inactive':
            fill = AppColors.failure.withOpacity(0.12);
            textColor = AppColors.failure;
            label = 'Expired';
            break;
          default:
            fill = AppColors.primary.withOpacity(0.12);
            textColor = AppColors.primary;
            label = 'Active';
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: CText(label, type: TextType.bodySmall, color: textColor),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CText(
                    'Learning Progress',
                    type: TextType.titleMedium,
                    color: AppColors.black,
                  ),
                  statusChip(),
                ],
              ),
              AppSpacing.verticalSpaceSmall,
              CText(
                '${progress.toStringAsFixed(progress >= 10 ? 0 : 1)}% complete',
                type: TextType.bodyMedium,
                color: AppColors.gray800,
              ),
              AppSpacing.verticalSpaceSmall,
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 8,
                  backgroundColor: AppColors.gray200,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              AppSpacing.verticalSpaceSmall,
              CText(
                progressLabel,
                type: TextType.bodySmall,
                color: AppColors.gray600,
              ),
              if (certificateIssued) ...[
                AppSpacing.verticalSpaceSmall,
                Row(
                  children: const [
                    Icon(Icons.verified, color: AppColors.success, size: 18),
                    SizedBox(width: 6),
                    CText(
                      'Certificate issued',
                      type: TextType.bodySmall,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
              if (expiry != null) ...[
                AppSpacing.verticalSpaceSmall,
                CText(
                  'Access until ${DateFormat('d MMM, yyyy').format(expiry)}',
                  type: TextType.bodySmall,
                  color: AppColors.gray600,
                ),
              ],
              if (enrolledOn != null) ...[
                AppSpacing.verticalSpaceTiny,
                CText(
                  'Enrolled on ${DateFormat('d MMM, yyyy').format(enrolledOn)}',
                  type: TextType.bodySmall,
                  color: AppColors.gray500,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final enrollmentModel = resolveEnrollment();

    Widget buildHighlights(
      CoursesState currentState,
      Map<String, dynamic>? course,
    ) {
      if (course == null) return const SizedBox.shrink();
      final stats = course['stats'] is Map<String, dynamic>
          ? course['stats'] as Map<String, dynamic>
          : const <String, dynamic>{};

      int? asInt(dynamic value) {
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value);
        return null;
      }

      String? formatCurrency(int? amount) {
        if (amount == null || amount <= 0) return null;
        final formatter = NumberFormat.decimalPattern();
        return formatter.format(amount);
      }

      String? formatHours(int? hours) {
        if (hours == null || hours <= 0) return null;
        if (hours >= 24) {
          final days = hours ~/ 24;
          final remHours = hours % 24;
          if (remHours == 0) {
            return '${days}d';
          }
          return '${days}d ${remHours}h';
        }
        return '${hours}h';
      }

      String? formatDays(int? days) {
        if (days == null || days <= 0) return null;
        return '${days}d';
      }

      String formatCount(int? value) {
        if (value == null) return '0';
        if (value < 1000) return value.toString();
        return NumberFormat.compact().format(value);
      }

      final enrollmentCost = formatCurrency(asInt(course['enrollmentCost']));
      final duration = formatHours(asInt(course['durationHours']));
      final validity = formatDays(asInt(course['validityDays']));
      final totalLectures = currentState.lectures.isNotEmpty
          ? currentState.lectures.length
          : asInt(stats['totalLectures']);
      final totalMaterials = currentState.materials.isNotEmpty
          ? currentState.materials.length
          : asInt(stats['totalMaterials']);
      final totalLecturers = currentState.lecturers.isNotEmpty
          ? currentState.lecturers.length
          : asInt(stats['totalLecturers']);
      final totalStudents = asInt(stats['totalStudents']);

      final highlights = <_HighlightData>[];
      if (enrollmentCost != null) {
        highlights.add(
          _HighlightData(
            icon: Icons.payments_outlined,
            label: 'Enrollment Fee',
            value: enrollmentCost,
          ),
        );
      }
      if (duration != null) {
        highlights.add(
          _HighlightData(
            icon: Icons.schedule,
            label: 'Duration',
            value: duration,
          ),
        );
      }
      if (validity != null) {
        highlights.add(
          _HighlightData(
            icon: Icons.calendar_today_outlined,
            label: 'Validity',
            value: validity,
          ),
        );
      }
      // if (totalLectures != null) {
      //   highlights.add(_HighlightData(
      //     icon: Icons.play_circle_outline,
      //     label: 'Lectures',
      //     value: formatCount(totalLectures),
      //   ));
      // }
      // if (totalMaterials != null) {
      //   highlights.add(_HighlightData(
      //     icon: Icons.menu_book_outlined,
      //     label: 'Materials',
      //     value: formatCount(totalMaterials),
      //   ));
      // }
      // if (totalLecturers != null) {
      //   highlights.add(_HighlightData(
      //     icon: Icons.school_outlined,
      //     label: 'Lecturers',
      //     value: formatCount(totalLecturers),
      //   ));
      // }
      // if (totalStudents != null && totalStudents > 0) {
      //   highlights.add(_HighlightData(
      //     icon: Icons.people_alt_outlined,
      //     label: 'Learners',
      //     value: formatCount(totalStudents),
      //   ));
      // }

      if (highlights.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CText('Highlights', type: TextType.titleMedium),
          AppSpacing.verticalSpaceSmall,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in highlights) _HighlightChip(data: item),
            ],
          ),
        ],
      );
    }

    // Build scaffold with refresh support and clearer error handling
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh course details
            await ref
                .read(coursesViewModelProvider.notifier)
                .getDetails(widget.courseId);
            // Also refresh the currently active tab's data
            _refreshCurrentTab();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              buildHeader(course),
              // buildEnrollmentOverview(enrollmentModel),
              if (course != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // buildHighlights(state, course),
                      // if (tags.isNotEmpty) ...[
                      //   AppSpacing.verticalSpaceMedium,
                      //   CText('Tags', type: TextType.titleSmall),
                      //   AppSpacing.verticalSpaceSmall,
                      //   Wrap(
                      //     spacing: 8,
                      //     runSpacing: 8,
                      //     children: [
                      //       for (final tag in tags)
                      //         Chip(
                      //           label: CText(
                      //             tag,
                      //             type: TextType.bodySmall,
                      //             color: AppColors.gray800,
                      //           ),
                      //           backgroundColor: AppColors.gray200,
                      //           materialTapTargetSize:
                      //               MaterialTapTargetSize.shrinkWrap,
                      //           padding:
                      //               const EdgeInsets.symmetric(horizontal: 4),
                      //         ),
                      //     ],
                      //   ),
                      //   AppSpacing.verticalSpaceMedium,
                      // ],
                      // AppSpacing.verticalSpaceMedium,
                    ],
                  ),
                ),
              if (isLoading)
                const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (error != null && details == null)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.failure,
                      ),
                      AppSpacing.verticalSpaceMedium,
                      CText(
                        error.message,
                        type: TextType.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.verticalSpaceMedium,
                      ReusableButton(
                        text: 'Retry',
                        onPressed: () => ref
                            .read(coursesViewModelProvider.notifier)
                            .getDetails(widget.courseId),
                      ),
                    ],
                  ),
                ),
              if (details != null) ...[
                Theme(
                  data: Theme.of(context).copyWith(
                    tabBarTheme: TabBarThemeData(
                      dividerColor:
                          Colors.transparent, // 👈 removes bottom line

                      overlayColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.focused) ||
                            states.contains(WidgetState.pressed)) {
                          return Colors
                              .transparent; // remove hover/press overlay
                        }
                        return null;
                      }),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.transparent,
                    unselectedLabelColor: AppColors.gray800,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      for (var i = 0; i < _tabTitles.length; i++)
                        ExploreTabContainer(
                          text: _tabTitles[i],
                          isSelected: _tabController.index == i,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IndexedStack(
                    index: _tabController.index,
                    children: const [
                      SyllabusInfo(),
                      MaterialsInfo(),
                      LecturesDetails(),
                      ClassesInfo(),
                      MockTestList(),
                      LecturersInfo(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: details != null && !state.isEnrolled
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SafeArea(
                child: Row(
                  children: [
                    // Enrollment fee on the left
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CText(
                            'Enrollment Fee',
                            type: TextType.bodySmall,
                            color: AppColors.gray600,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (course != null) ...[
                                if (course['hasOffer'] == true &&
                                    course['enrollmentCost'] != null &&
                                    course['discountedPrice'] != null &&
                                    (course['enrollmentCost'] as num) >
                                        (course['discountedPrice'] as num)) ...[
                                  // Discounted Price
                                  CText(
                                    'Rs. ${NumberFormat.decimalPattern().format(course['discountedPrice'])}',
                                    type: TextType.headlineSmall,
                                    color: AppColors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  const SizedBox(width: 4),
                                  // Original Price (Strikethrough)
                                  Text(
                                    'Rs. ${NumberFormat.decimalPattern().format(course['enrollmentCost'])}',
                                    style: const TextStyle(
                                      fontSize:
                                          12.0, // Assuming bodySmall size, adjust if needed
                                      color: Color.fromRGBO(123, 138, 153, 1),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ] else ...[
                                  // Regular Price
                                  CText(
                                    (course['enrollmentCost'] != null &&
                                            (course['enrollmentCost'] is num))
                                        ? ((course['enrollmentCost'] as num) ==
                                                  0
                                              ? 'Free'
                                              : 'Rs. ${NumberFormat.decimalPattern().format(course['enrollmentCost'])}')
                                        : 'Rs. 0',
                                    type: TextType.headlineSmall,
                                    color: AppColors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ] else ...[
                                const CText(
                                  'Rs. 0',
                                  type: TextType.headlineSmall,
                                  color: AppColors.black,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Enroll button on the right
                    if (((course != null &&
                            course['hasOffer'] == true &&
                            course['discountedPrice'] != null)
                        ? ((course['discountedPrice'] as num) <= 0)
                        : (((course?['enrollmentCost'] as num?) ?? 0) <= 0)))
                      ReusableButton(
                        text: 'Enroll Now',
                        onPressed: _handleFreeEnrollment,
                        backgroundColor: AppColors.secondary,
                      )
                    else
                      EnrollWithEsewaButton(
                        courseId: widget.courseId,
                        isEnrolled: false,
                        promoCode: null,
                        enrollType: 'course_enrollment',
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  /// Force refresh the currently selected tab's data
  void _refreshCurrentTab() {
    if (!mounted) return;
    final index = _tabController.index;
    if (index <= 0) return; // Syllabus tab does not need remote fetch

    final currentState = ref.read(coursesViewModelProvider);
    if (!currentState.isEnrolled) {
      debugPrint('Refresh: user not enrolled, skipping tab refresh');
      return;
    }

    final notifier = ref.read(coursesViewModelProvider.notifier);
    final courseId = widget.courseId;
    debugPrint('Refreshing current tab -> ${_tabTitles[index]} (index $index)');

    switch (index) {
      case 1:
        notifier.refreshMaterials(courseId, force: true);
        break;
      case 2:
        notifier.refreshLectures(courseId, force: true);
        break;
      case 3:
        notifier.refreshClasses(courseId, force: true);
        break;
      case 4:
        notifier.refreshMockTests(courseId, force: true);
        break;
      case 5:
        notifier.refreshLecturers(courseId, force: true);
        break;
      default:
        break;
    }
  }

  void _handleTabSelection(int index) {
    if (!mounted) return;
    final currentState = ref.read(coursesViewModelProvider);
    if (index <= 0) return; // Syllabus tab does not trigger remote fetch
    if (!currentState.isEnrolled) {
      debugPrint(
        'Tab "${_tabTitles[index]}" selected but user not enrolled; skipping secured fetch.',
      );
      return;
    }

    final notifier = ref.read(coursesViewModelProvider.notifier);
    final courseId = widget.courseId;
    debugPrint('Tab selected -> ${_tabTitles[index]} (index $index)');
    switch (index) {
      case 1:
        notifier.refreshMaterials(courseId);
        break;
      case 2:
        notifier.refreshLectures(courseId);
        break;
      case 3:
        notifier.refreshClasses(courseId);
        break;
      case 4:
        notifier.refreshMockTests(courseId);
        break;
      case 5:
        notifier.refreshLecturers(courseId);
        break;
      default:
        break;
    }
  }
}

class _HighlightData {
  const _HighlightData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.data});

  final _HighlightData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CText(
                data.value,
                type: TextType.bodySmall,
                color: AppColors.black,
              ),
              CText(
                data.label,
                type: TextType.bodySmall,
                color: AppColors.gray600,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
