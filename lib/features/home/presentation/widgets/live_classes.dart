import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../../courses/presentation/pages/meeting_page_v2.dart';
import '../../../courses/view_model/live_class_join_view_model.dart';
import '../../models/homepage_models.dart' as home_models;

class LiveClasses extends ConsumerWidget {
  const LiveClasses({
    super.key,
    required this.liveClasses,
    this.isLoading = false,
    this.isUpcoming = false,
  });

  final List<home_models.LiveClass> liveClasses;
  final bool isLoading;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (liveClasses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: CText(
          'No live classes scheduled right now.',
          type: TextType.bodySmall,
          color: AppColors.gray500,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: liveClasses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final liveClass = liveClasses[index];
        final scheduledText = liveClass.scheduledAt != null
            ? DateTimeHelper.formatForUI(liveClass.scheduledAt!.toLocal())
            : 'Schedule to be announced';

        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomCachedNetworkImage(
                    imageUrl: liveClass.thumbnailUrl ?? AppAssets.dummyNetImg,
                    size: Size(60, 60),
                    fitStatus: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CText(
                        liveClass.title ?? 'Upcoming live class',
                        type: TextType.bodyMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      CText(
                        scheduledText,
                        type: TextType.bodySmall,
                        color: AppColors.gray600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Join Now Button
                ElevatedButton(
                  onPressed: isUpcoming
                      ? null
                      : () async {
                          if (liveClass.id != null) {
                            final notifier = ref.read(
                              liveClassJoinViewModelProvider.notifier,
                            );
                            final token = await notifier.joinLiveClass(
                              liveClass.id!,
                            );

                            if (token != null && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MeetingPageV2(
                                    token: token,
                                    classId: liveClass.id!,
                                  ),
                                ),
                              ).then((_) {
                                notifier.reset();
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUpcoming
                        ? AppColors.gray300
                        : AppColors.secondary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: CText(
                    isUpcoming ? 'Upcoming' : 'Join Now',
                    type: TextType.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
