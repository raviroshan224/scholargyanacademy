import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../view_model/course_view_model.dart';

class LecturersInfo extends ConsumerWidget {
  const LecturersInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coursesViewModelProvider);
    final lecturers = state.lecturers;

    if (!state.isEnrolled) {
      return const Center(child: CText('Enroll to access lecturers'));
    }

    if (state.loadingLecturers && lecturers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.lecturersError != null && lecturers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CText(
            state.lecturersError!.message,
            type: TextType.bodyMedium,
            color: AppColors.failure,
          ),
        ),
      );
    }

    if (lecturers.isEmpty) {
      return const Center(child: CText('No lecturers available'));
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: lecturers.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final lect = lecturers[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gray200,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: lect.profileImageUrl != null
                      ? NetworkImage(lect.profileImageUrl!) as ImageProvider
                      : AssetImage(AppAssets.loginBg),
                  radius: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CText(lect.fullName,
                          type: TextType.titleMedium, color: AppColors.black),
                      const SizedBox(height: 4),
                      if ((lect.subjects ?? '').isNotEmpty)
                        CText(lect.subjects!,
                            type: TextType.bodySmall,
                            color: AppColors.gray600,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
