import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../data/models/exam_models.dart';
import '../providers/exam_detail_view_model.dart';
import '../../../courses/presentation/pages/enrolled_course_details_page.dart';

class ExamDetailPage extends ConsumerStatefulWidget {
  const ExamDetailPage({super.key, required this.examId});

  final String examId;

  @override
  ConsumerState<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends ConsumerState<ExamDetailPage> {
  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(examDetailViewModelProvider.notifier)
          .loadExamDetail(widget.examId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examDetailViewModelProvider);
    final detail = state.detail;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.title ?? 'Exam Detail'),
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        foregroundColor: AppColors.primary,
        elevation: 2,
      ),
      backgroundColor: AppColors.white,
      body: state.isLoading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && detail == null
              ? _ErrorView(
                  message: state.error!.message,
                  onRetry: () => ref
                      .read(examDetailViewModelProvider.notifier)
                      .loadExamDetail(widget.examId, force: true),
                )
              : detail == null
                  ? const _ErrorView(
                      message: 'Exam details are unavailable.',
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl:
                                  detail.examImageUrl ?? AppAssets.dummyNetImg,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                AppAssets.errorImage,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: CText(
                                        detail.title,
                                        type: TextType.headlineSmall,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    if (state.isLoading)
                                      const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                  ],
                                ),
                                AppSpacing.verticalSpaceSmall,
                                // Clean status and category badges
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (detail.category != null &&
                                        detail.category!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: CText(
                                          detail.category!,
                                          type: TextType.bodySmall,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (detail.status != null &&
                                        detail.status!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: detail.status!.toLowerCase() ==
                                                  'active'
                                              ? AppColors.success
                                                  .withOpacity(0.1)
                                              : AppColors.gray500
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: CText(
                                          detail.status!,
                                          type: TextType.bodySmall,
                                          color: detail.status!.toLowerCase() ==
                                                  'active'
                                              ? AppColors.success
                                              : AppColors.gray500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),

                                if (detail.description != null &&
                                    detail.description!.isNotEmpty) ...[
                                  AppSpacing.verticalSpaceMedium,
                                  const CText(
                                    'Description',
                                    type: TextType.bodyLarge,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  AppSpacing.verticalSpaceSmall,
                                  Html(
                                    data: detail.description,
                                    style: {
                                      'body': Style(
                                        margin: Margins.zero,
                                        padding: HtmlPaddings.zero,
                                        fontSize: FontSize(14),
                                        color: AppColors.gray700,
                                      ),
                                    },
                                  ),
                                ],

                                if (detail.courseDetails.isNotEmpty) ...[
                                  AppSpacing.verticalSpaceMedium,
                                  const CText(
                                    'Course Details',
                                    type: TextType.bodyLarge,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  AppSpacing.verticalSpaceSmall,
                                  Column(
                                    children: detail.courseDetails
                                        .map((course) => _CourseDetailSection(
                                            course: course))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _CourseDetailSection extends StatelessWidget {
  const _CourseDetailSection({required this.course});

  final ExamCourseInfo course;

  @override
  Widget build(BuildContext context) {
    final courseId = course.id;
    return InkWell(
        onTap: () {
          if (courseId == null || courseId.isEmpty) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EnrolledCourseDetailsPage(courseId: courseId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 64,
                  width: 64,
                  child: CustomCachedNetworkImage(
                    imageUrl: course.thumbnail ?? AppAssets.dummyNetImg,
                    fitStatus: BoxFit.cover,
                  ),
                ),
              ),
              AppSpacing.horizontalSpaceMedium,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CText(
                      course.title,
                      type: TextType.bodyMedium,
                      fontWeight: FontWeight.w600,
                    ),
                    AppSpacing.verticalSpaceSmall,
                    _KeyValueList(
                      entries: [
                        if (course.classCount != null)
                          MapEntry('Class Count', course.classCount.toString()),
                        if (course.description != null &&
                            course.description!.isNotEmpty)
                          MapEntry('Description', course.description!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class _KeyValueList extends StatelessWidget {
  const _KeyValueList({required this.entries});

  final List<MapEntry<String, String>> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray600,
                  ),
                  children: [
                    TextSpan(
                      text: '${entry.key}: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                    TextSpan(text: entry.value),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: AppColors.gray100,
      label: Text('$label: $value'),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CText(
              message,
              type: TextType.bodySmall,
              color: AppColors.failure,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.verticalSpaceMedium,
              ReusableButton(
                text: 'Retry',
                onPressed: onRetry!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
