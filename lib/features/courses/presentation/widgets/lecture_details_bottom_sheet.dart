import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../model/course_models.dart';

class LectureDetailsBottomSheet extends StatelessWidget {
  final LectureModel lecture;
  final VoidCallback onJoinClass;

  const LectureDetailsBottomSheet({
    super.key,
    required this.lecture,
    required this.onJoinClass,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16,
                      80), // Extra bottom padding for floating button
                  children: [
                    // Thumbnail
                    if (lecture.thumbnailUrl != null ||
                        lecture.coverImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomCachedNetworkImage(
                          imageUrl:
                              (lecture.thumbnailUrl ?? lecture.coverImageUrl)!,
                          fitStatus: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Title
                    CText(
                      lecture.name,
                      type: TextType.titleMedium,
                      fontWeight: FontWeight.bold,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    if (lecture.description != null &&
                        lecture.description!.isNotEmpty)
                      CText(
                        lecture.description!,
                        type: TextType.bodyMedium,
                        color: AppColors.gray600,
                      )
                    else
                      const CText(
                        'No description available.',
                        type: TextType.bodyMedium,
                        color: AppColors.gray400,
                        // fontStyle: FontStyle.italic,
                      ),
                    const SizedBox(height: 24),

                    // Lecturer Information Section
                    const CText(
                      'Lecturer',
                      type: TextType.titleSmall,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: (lecture.lecturerProfileImageUrl !=
                                      null &&
                                  lecture.lecturerProfileImageUrl!.isNotEmpty)
                              ? NetworkImage(lecture.lecturerProfileImageUrl!)
                              : null,
                          child: (lecture.lecturerProfileImageUrl == null ||
                                  lecture.lecturerProfileImageUrl!.isEmpty)
                              ? const Icon(Icons.person,
                                  color: AppColors.primary)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CText(
                              (lecture.lecturerName != null &&
                                      lecture.lecturerName!.isNotEmpty)
                                  ? lecture.lecturerName!
                                  : 'Lecturer not assigned',
                              type: TextType.bodyMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Join Class Button (Fixed at bottom or part of column)
              // Since we are inside a Column with Expanded ListView, we can put the button below the list.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ReusableButton(
                    text: 'Join Class',
                    onPressed: onJoinClass,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
