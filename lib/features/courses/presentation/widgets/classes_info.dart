import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/core.dart';
import '../../model/course_models.dart';
import '../../view_model/course_view_model.dart';

class ClassesInfo extends ConsumerWidget {
  const ClassesInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coursesViewModelProvider);
    
    // CRITICAL: Check enrollment first
    // Live classes API requires enrollment
    if (!state.isEnrolled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.gray400,
              ),
              SizedBox(height: 16),
              CText(
                'Enroll in this course to access live classes',
                type: TextType.bodyLarge,
                textAlign: TextAlign.center,
                color: AppColors.gray700,
              ),
            ],
          ),
        ),
      );
    }
    
    // For enrolled users: show classes from API
    final schedule = state.classes;

    if (state.loadingClasses && schedule.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.classesError != null && schedule.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CText(
            state.classesError!.message,
            type: TextType.bodyMedium,
            color: AppColors.failure,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (schedule.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CText(
            'No live classes are scheduled for this course',
            type: TextType.bodyMedium,
            color: AppColors.gray600,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        final item = schedule[index];
        final title = item.title.isNotEmpty ? item.title : 'Class ${index + 1}';
        final description = item.description;
        final startsAt = _formatDateTime(
              item.startTime ??
                  item.raw['startTime'] ??
                  item.raw['startsAt'] ??
                  item.raw['scheduledAt'],
            ) ??
            _extractStartLabel(item.raw);
        final duration = item.durationLabel ??
            item.raw['duration']?.toString() ??
            item.raw['durationText']?.toString();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Card(
            elevation: 0,
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.gray200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CText(
                    title,
                    type: TextType.bodyLarge,
                    color: AppColors.black,
                  ),
                  if (startsAt != null) ...[
                    AppSpacing.verticalSpaceTiny,
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        CText(
                          startsAt,
                          type: TextType.bodySmall,
                          color: AppColors.gray600,
                        ),
                      ],
                    ),
                  ],
                  if (duration != null && duration.isNotEmpty) ...[
                    AppSpacing.verticalSpaceTiny,
                    Row(
                      children: [
                        const Icon(Icons.timelapse,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        CText(
                          duration,
                          type: TextType.bodySmall,
                          color: AppColors.gray600,
                        ),
                      ],
                    ),
                  ],
                  if ((description ?? '').isNotEmpty) ...[
                    AppSpacing.verticalSpaceSmall,
                    CText(
                      description!,
                      type: TextType.bodySmall,
                      color: AppColors.gray700,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _formatDateTime(dynamic value) {
    if (value == null) return null;
    DateTime? parsed;
    if (value is String) {
      parsed = DateTime.tryParse(value);
    } else if (value is DateTime) {
      parsed = value;
    }
    if (parsed == null) return null;
    final formatter = DateFormat('EEE, d MMM • hh:mm a');
    return formatter.format(parsed.toLocal());
  }

  String? _extractStartLabel(Map<String, dynamic> raw) {
    const keys = [
      'startTimeText',
      'scheduleText',
      'startLabel',
      'startsAtText'
    ];
    for (final key in keys) {
      final value = raw[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  List<CourseClassModel> _fallbackClassesFromDetails(
      Map<String, dynamic>? details) {
    if (details == null) return const <CourseClassModel>[];
    final List<CourseClassModel> results = [];
    void parse(dynamic source) {
      if (source is List) {
        for (final item in source) {
          if (item is Map<String, dynamic>) {
            results.add(CourseClassModel.fromJson(item));
          } else if (item is Map) {
            results.add(
              CourseClassModel.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
    }

    parse(details['classes']);
    final enrollment = details['enrollmentDetails'];
    if (results.isEmpty && enrollment is Map<String, dynamic>) {
      parse(enrollment['classes']);
    } else if (results.isEmpty && enrollment is Map) {
      final map = Map<String, dynamic>.from(enrollment);
      parse(map['classes']);
    }
    return results;
  }
}
