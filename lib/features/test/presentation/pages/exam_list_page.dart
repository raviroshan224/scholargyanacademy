import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../models/exam_models.dart';
import '../../view_model/exam_view_model.dart';
import '../widgets/available_test.dart';
import '../../../../features/exams/presentation/pages/exam_detail_page.dart';

class ExamListPage extends ConsumerStatefulWidget {
  const ExamListPage({super.key});

  @override
  ConsumerState<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends ConsumerState<ExamListPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final notifier = ref.read(examViewModelProvider.notifier);
    await notifier.loadExamList(
      force: true,
      status: 'Active',
      sortOrder: 'desc',
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(examViewModelProvider.notifier).loadExamList(
            force: true,
            search: value.trim().isEmpty ? null : value.trim(),
            status: 'Active',
            sortOrder: 'desc',
          );
    });
  }

  Future<void> _onRefresh() async {
    final state = ref.read(examViewModelProvider);
    await ref.read(examViewModelProvider.notifier).loadExamList(
          force: true,
          search: _searchController.text.trim().isEmpty
              ? state.search
              : _searchController.text.trim(),
          status: state.status ?? 'Active',
          sortOrder: state.sortOrder ?? 'desc',
        );
  }

  @override
  Widget build(BuildContext context) {
    final examState = ref.watch(examViewModelProvider);
    final examNotifier = ref.read(examViewModelProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(title: 'Active Exams'),
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.verticalSpaceMedium,
            CustTextField(
              controller: _searchController,
              hintText: 'Search exams',
              onFieldChanged: _onSearchChanged,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(Icons.search, color: AppColors.gray500),
              ),
            ),
            AppSpacing.verticalSpaceMedium,
            Expanded(
              child: AvailableList(
                exams: examState.exams,
                isLoading: examState.loadingList,
                isLoadingMore: examState.loadingMore,
                errorMessage: examState.listError?.message,
                onRefresh: _onRefresh,
                onLoadMore: examNotifier.loadNextPage,
                onExamTap: (ExamListItem exam) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExamDetailPage(examId: exam.id),
                    ),
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
