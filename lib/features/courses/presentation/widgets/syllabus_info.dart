import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../view_model/course_view_model.dart';

class SyllabusInfo extends ConsumerWidget {
  const SyllabusInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coursesViewModelProvider);
    final subjects = state.subjects;

    if (state.loadingSubjects && subjects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.subjectsError != null && subjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CText(
            state.subjectsError!.message,
            type: TextType.bodyMedium,
            color: AppColors.failure,
          ),
        ),
      );
    }

    if (subjects.isEmpty) {
      return const Center(child: CText('No syllabus available'));
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: subjects.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final chapters = subject.chapters;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.gray300,
                width: 1,
              ),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                backgroundColor: AppColors.white,
                collapsedBackgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: CText(
                  '${index + 1}. ${subject.subjectName}',
                  type: TextType.titleMedium,
                ),
                children: [
                  if (chapters.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CText('No chapters available',
                          type: TextType.bodySmall, color: AppColors.gray600),
                    )
                  else
                    for (var i = 0; i < chapters.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 2.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            title: CText(
                              '${i + 1}. ${chapters[i].chapterTitle}',
                              type: TextType.bodyMedium,
                            ),
                            onTap: () {},
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
