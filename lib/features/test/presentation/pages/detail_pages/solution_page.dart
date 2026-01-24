import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../models/test_session_models.dart';
import '../../../view_model/test_outcome_view_model.dart';

class SolutionsPage extends ConsumerWidget {
  const SolutionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solutionsState = ref.watch(testSolutionsControllerProvider);
    final solutions = solutionsState.items;
    final isLoading = solutionsState.isLoading;
    final error = solutionsState.error;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Solutions',
        leadingIcon: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading && solutions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : solutions.isEmpty
              ? Center(
                  child: CText(
                    error?.message ?? 'Solutions are not available yet.',
                    type: TextType.bodySmall,
                    color: AppColors.gray600,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: solutions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final solution = solutions[index];
                    return _SolutionCard(solution: solution, index: index + 1);
                  },
                ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({
    required this.solution,
    required this.index,
  });

  final TestSolution solution;
  final int index;

  @override
  Widget build(BuildContext context) {
    final questionPrompt =
        solution.question?.prompt ?? solution.questionText ?? 'Question $index';
    final questionDescription = solution.question?.description;

    final entries = _resolveOptions(solution);
    final correctKey = solution.correctOptionKey?.toLowerCase();
    final selectedKey = solution.selectedAnswerKey?.toLowerCase();
    final selectedText = _resolveSelectedText(entries, selectedKey) ??
        _resolveSelectedFromQuestion(solution.question, selectedKey);
    final correctText = _resolveCorrectText(
      entries,
      solution.correctAnswerText,
      correctKey,
      solution.question,
    );
    final normalizedCorrectText = _normalize(correctText);

    final statusDetails = _statusChipData(
      selectedText: selectedText,
      correctText: correctText,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CText(
              '$index. $questionPrompt',
              type: TextType.bodyMedium,
              color: AppColors.black,
            ),
            if (questionDescription != null &&
                questionDescription.isNotEmpty) ...[
              AppSpacing.verticalSpaceSmall,
              CText(
                questionDescription,
                type: TextType.bodySmall,
                color: AppColors.gray700,
              ),
            ],
            AppSpacing.verticalSpaceAverage,
            ...entries.asMap().entries.map((entry) {
              final optionKey = entry.value.key;
              final optionText = entry.value.value;
              final optionIndex = entry.key;
              final label = _optionLabel(optionIndex);
              final isSelected =
                  selectedKey != null && optionKey.toLowerCase() == selectedKey;
              final matchesCorrectText = normalizedCorrectText.isNotEmpty
                  ? _normalize(optionText) == normalizedCorrectText
                  : false;
              final matchesCorrectKey =
                  correctKey != null && optionKey.toLowerCase() == correctKey;
              final isCorrect = matchesCorrectText || matchesCorrectKey;

              return _OptionTile(
                label: label,
                text: optionText,
                isCorrect: isCorrect,
                isSelected: isSelected && !isCorrect,
              );
            }),
            if (solution.explanation != null &&
                solution.explanation!.isNotEmpty) ...[
              AppSpacing.verticalSpaceAverage,
              CText(
                'Explanation:',
                type: TextType.bodyMedium,
                color: AppColors.black,
              ),
              AppSpacing.verticalSpaceSmall,
              CText(
                solution.explanation!,
                type: TextType.bodySmall,
                color: AppColors.gray700,
              ),
            ],
            AppSpacing.verticalSpaceAverage,
            Row(
              children: [
                CText(
                  'Result:',
                  type: TextType.bodyMedium,
                  color: AppColors.black,
                ),
                AppSpacing.horizontalSpaceSmall,
                Chip(
                  label: CText(
                    statusDetails.label,
                    type: TextType.bodySmall,
                    color: statusDetails.color,
                  ),
                  backgroundColor: statusDetails.color.withOpacity(0.12),
                  side: BorderSide(color: statusDetails.color.withOpacity(0.4)),
                ),
              ],
            ),
            AppSpacing.verticalSpaceSmall,
            CText(
              'Your answer: ${selectedText ?? 'Not answered'}',
              type: TextType.bodySmall,
              color: AppColors.gray700,
            ),
            if (correctText != null && correctText.isNotEmpty) ...[
              AppSpacing.verticalSpaceSmall,
              CText(
                'Correct answer: $correctText',
                type: TextType.bodySmall,
                color: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.text,
    required this.isCorrect,
    required this.isSelected,
  });

  final String label;
  final String text;
  final bool isCorrect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final bool highlightCorrect = isCorrect;
    final bool highlightSelected = !highlightCorrect && isSelected;

    Color background = AppColors.lightGreyBg;
    Color borderColor = Colors.transparent;
    final List<Widget> badges = <Widget>[];

    if (highlightCorrect) {
      background = AppColors.successWithOpacity(0.12);
      borderColor = AppColors.successWithOpacity(0.4);
      badges.add(_buildBadge('Correct Answer', AppColors.success));
    } else if (highlightSelected) {
      background = AppColors.primaryWithOpacity(0.12);
      borderColor = AppColors.primaryWithOpacity(0.4);
      badges.add(_buildBadge('Your Answer', AppColors.primary));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray300),
            ),
            child: CText(
              label,
              type: TextType.bodySmall,
              color: AppColors.heading,
            ),
          ),
          AppSpacing.horizontalSpaceAverage,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CText(
                  text,
                  type: TextType.bodySmall,
                  color: AppColors.black,
                ),
                if (badges.isNotEmpty) ...[
                  AppSpacing.verticalSpaceSmall,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: badges,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: CText(
        text,
        type: TextType.bodySmall,
        color: color,
      ),
    );
  }
}

class _StatusChipData {
  const _StatusChipData({required this.label, required this.color});

  final String label;
  final Color color;
}

_StatusChipData _statusChipData({String? selectedText, String? correctText}) {
  if (selectedText == null || selectedText.trim().isEmpty) {
    return const _StatusChipData(
        label: 'Not answered', color: AppColors.gray600);
  }
  if (correctText == null || correctText.trim().isEmpty) {
    return const _StatusChipData(label: 'Answered', color: AppColors.primary);
  }
  final isCorrect = _normalize(selectedText) == _normalize(correctText);
  return isCorrect
      ? const _StatusChipData(label: 'Correct', color: AppColors.success)
      : const _StatusChipData(label: 'Incorrect', color: AppColors.failure);
}

List<MapEntry<String, String>> _resolveOptions(TestSolution solution) {
  final LinkedHashMap<String, String> ordered = LinkedHashMap<String, String>();
  const defaultOrder = [
    'option1',
    'option2',
    'option3',
    'option4',
    'option5',
    'option6'
  ];

  void insertOrdered(String key, String value) {
    if (key.isEmpty || value.trim().isEmpty) {
      return;
    }
    ordered[key] = value.trim();
  }

  final sourceOptions = Map<String, String>.from(solution.options);
  for (final key in defaultOrder) {
    final value = sourceOptions.remove(key);
    if (value != null) {
      insertOrdered(key, value);
    }
  }
  if (sourceOptions.isNotEmpty) {
    final remaining = sourceOptions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in remaining) {
      insertOrdered(entry.key, entry.value);
    }
  }

  if (ordered.isEmpty && solution.question != null) {
    final questionOptions = solution.question!.options;
    for (var i = 0; i < questionOptions.length; i++) {
      final option = questionOptions[i];
      final key = option.key.isNotEmpty ? option.key : 'option${i + 1}';
      insertOrdered(key, option.label);
    }
  }

  return ordered.entries.toList();
}

String _optionLabel(int index) {
  const baseCode = 65; // 'A'
  return String.fromCharCode(baseCode + index);
}

String? _resolveSelectedText(
  List<MapEntry<String, String>> options,
  String? selectedKey,
) {
  if (selectedKey == null || selectedKey.isEmpty) {
    return null;
  }
  final entry = options.firstWhere(
    (element) => element.key.toLowerCase() == selectedKey,
    orElse: () => const MapEntry<String, String>('', ''),
  );
  if (entry.key.isEmpty) {
    return null;
  }
  return entry.value;
}

String? _resolveSelectedFromQuestion(
    TestQuestion? question, String? selectedKey) {
  if (question == null || selectedKey == null || selectedKey.isEmpty) {
    return null;
  }
  final option = question.options.firstWhere(
    (element) => element.key.toLowerCase() == selectedKey,
    orElse: () => const TestQuestionOption(key: '', label: ''),
  );
  if (option.key.isEmpty && option.label.isEmpty) {
    return null;
  }
  return option.label.isNotEmpty ? option.label : null;
}

String? _resolveCorrectText(
  List<MapEntry<String, String>> options,
  String? correctAnswerText,
  String? correctKey,
  TestQuestion? question,
) {
  String? resolved = correctAnswerText;
  if (resolved == null || resolved.trim().isEmpty) {
    if (correctKey != null && correctKey.isNotEmpty) {
      final entry = options.firstWhere(
        (element) => element.key.toLowerCase() == correctKey,
        orElse: () => const MapEntry<String, String>('', ''),
      );
      if (entry.key.isNotEmpty) {
        resolved = entry.value;
      }
    }
  }
  if ((resolved == null || resolved.trim().isEmpty) && question != null) {
    final option = question.options.firstWhere(
      (element) =>
          (correctKey != null && element.key.toLowerCase() == correctKey) ||
          element.isCorrect == true,
      orElse: () => const TestQuestionOption(key: '', label: ''),
    );
    if (option.key.isNotEmpty || option.label.isNotEmpty) {
      resolved = option.label;
    }
  }
  return resolved;
}

String _normalize(String? value) {
  if (value == null) return '';
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
