import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../data/models/exam_models.dart';
import '../providers/exam_list_view_model.dart';
import 'exam_detail_page.dart';

class ExamListPage extends ConsumerStatefulWidget {
  const ExamListPage({super.key});

  @override
  ConsumerState<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends ConsumerState<ExamListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _status = ValueNotifier<String>('Active');
  final ValueNotifier<String?> _sortBy = ValueNotifier<String?>(null);
  final ValueNotifier<String> _sortOrder = ValueNotifier<String>('desc');
  final ValueNotifier<int> _limit = ValueNotifier<int>(10);
  Timer? _debounce;
  late final ScrollController _scrollController;

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _status.dispose();
    _sortBy.dispose();
    _sortOrder.dispose();
    _limit.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = 200.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current < maxScroll - threshold) return;

    final state = ref.read(examListViewModelProvider);
    final notifier = ref.read(examListViewModelProvider.notifier);
    if (state.canLoadMore && !state.isLoadingMore) {
      notifier.loadExams(page: state.page + 1, append: true, force: true);
    }
  }

  void _scheduleSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final statusParam = _status.value == 'All' ? null : _status.value;
      ref.read(examListViewModelProvider.notifier).loadExams(
            page: 1, // Reset to first page on search
            search: query.trim().isEmpty ? null : query.trim(),
            status: statusParam,
            sortBy: _sortBy.value,
            sortOrder: _sortOrder.value,
            limit: _limit.value,
            append: false, // Clear existing data
            force: true,
          );
    });
  }

  void _applyFilters() {
    final statusParam = _status.value == 'All' ? null : _status.value;
    ref.read(examListViewModelProvider.notifier).loadExams(
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          status: statusParam,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
          limit: _limit.value,
          force: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examListViewModelProvider);
    final notifier = ref.read(examListViewModelProvider.notifier);
    final meta = state.meta;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Exams'),
      backgroundColor: AppColors.white,
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustTextField(
                    controller: _searchController,
                    hintText: 'Search by title, category, or course',
                    onFieldChanged: _scheduleSearch,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.search, color: AppColors.gray500),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status filter chips are commented out temporarily
                  // ValueListenableBuilder<String>(
                  //   valueListenable: _status,
                  //   builder: (context, currentStatus, _) {
                  //     return Wrap(
                  //       spacing: 8,
                  //       children: ['All', 'Active', 'Inactive'].map((status) {
                  //         final isSelected = currentStatus == status;
                  //         return FilterChip(
                  //           selected: isSelected,
                  //           label: CText(
                  //             status,
                  //             type: TextType.bodySmall,
                  //             color: isSelected ? AppColors.white : AppColors.gray700,
                  //           ),
                  //           backgroundColor: AppColors.gray100,
                  //           selectedColor: AppColors.primary,
                  //           onSelected: (selected) {
                  //             if (selected) {
                  //               _status.value = status;
                  //               _applyFilters();
                  //             }
                  //           },
                  //           shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(20),
                  //             side: BorderSide(
                  //               color: isSelected ? AppColors.primary : AppColors.gray300,
                  //             ),
                  //           ),
                  //         );
                  //       }).toList(),
                  //     );
                  //   },
                  // ),
                  if (state.error != null) ...[
                    AppSpacing.verticalSpaceSmall,
                    _ErrorBanner(
                      message: state.error!.message,
                      onRetry: _applyFilters,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: state.isLoading && state.exams.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.exams.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: CText(
                                  'No exams found. Adjust the filters to try again.',
                                  type: TextType.bodySmall,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: state.exams.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.exams.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            final exam = state.exams[index];
                            return _ExamCard(
                              exam: exam,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ExamDetailPage(examId: exam.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.onTap,
  });

  final ExamSummary exam;
  final VoidCallback onTap;

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    // Determine status color
    Color statusColor = AppColors.gray500;
    if (exam.status?.toLowerCase() == 'active') {
      statusColor = AppColors.success;
    } else if (exam.status?.toLowerCase() == 'inactive') {
      statusColor = AppColors.gray500;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: CustomCachedNetworkImage(
                    imageUrl: exam.examImageUrl ?? AppAssets.dummyNetImg,
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
                      exam.title,
                      type: TextType.bodyLarge,
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    AppSpacing.verticalSpaceSmall,
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (exam.category != null && exam.category!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CText(
                              exam.category!,
                              type: TextType.bodySmall,
                              color: AppColors.primary,
                            ),
                          ),
                        if (exam.status != null && exam.status!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CText(
                              exam.status!,
                              type: TextType.bodySmall,
                              color: statusColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow icon
              const Icon(
                Icons.chevron_right,
                color: AppColors.gray400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseDetailTile extends StatelessWidget {
  const _CourseDetailTile({required this.course});

  final ExamCourseInfo course;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
        color: AppColors.gray100,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 56,
              width: 56,
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
                  color: AppColors.black,
                ),
                if (course.description != null &&
                    course.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: CText(
                      course.description!,
                      type: TextType.bodySmall,
                      color: AppColors.gray600,
                    ),
                  ),
                if (course.classCount != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: CText(
                      'Classes: ${course.classCount}',
                      type: TextType.bodySmall,
                      color: AppColors.gray600,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CText(
                    'ID: ${course.id}',
                    type: TextType.bodySmall,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Footer pagination removed — pagination is handled via infinite scroll.

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

class _InfoText extends StatelessWidget {
  const _InfoText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return CText(
      '$label: $value',
      type: TextType.bodySmall,
      color: AppColors.gray600,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.failureWithOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
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
            child: CText('Retry', type: TextType.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.valueListenable,
    required this.options,
    required this.onChanged,
    required this.displayBuilder,
  });

  final String label;
  final ValueListenable<T> valueListenable;
  final List<T> options;
  final ValueChanged<T?> onChanged;
  final String Function(T value) displayBuilder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: valueListenable,
      builder: (context, value, _) {
        return SizedBox(
          height: 48,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                onChanged: onChanged,
                items: options
                    .map(
                      (option) => DropdownMenuItem<T>(
                        value: option,
                        child: Text(displayBuilder(option)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
