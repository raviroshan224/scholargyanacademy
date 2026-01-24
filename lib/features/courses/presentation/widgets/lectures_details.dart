import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/config/services/remote_services/api_endpoints.dart';
import 'package:scholarsgyanacademy/config/services/secure_storage_provider.dart';

import '../../../../core/core.dart';
import '../../model/course_models.dart';
import '../../view_model/course_view_model.dart';
import '../pages/video_player_page.dart';

Future<void> _openLecture(
  BuildContext context,
  WidgetRef ref,
  LectureModel lecture,
  bool isEnrolled,
) async {
  if (!isEnrolled) {
    AppMethods.showCustomSnackBar(
      context: context,
      message: 'Please enroll to access this lecture.',
      isError: true,
    );
    return;
  }

  final notifier = ref.read(coursesViewModelProvider.notifier);
  final result = await notifier.lectureWatchLink(lecture.id);
  result.fold(
    (failure) => AppMethods.showCustomSnackBar(
      context: context,
      message: failure.message,
      isError: true,
    ),
    (watchUrl) async {
      if (watchUrl == null || watchUrl.isEmpty) {
        AppMethods.showCustomSnackBar(
          context: context,
          message: 'No playback link available yet',
          isError: true,
        );
        return;
      }
      final playbackHeaders = await _resolvePlaybackHeaders(ref, watchUrl);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerPage(
            url: watchUrl,
            title: lecture.name,
            headers: playbackHeaders,
          ),
        ),
      );
    },
  );
}

class LecturesDetails extends ConsumerWidget {
  const LecturesDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coursesViewModelProvider);
    final lectures = state.lectures;
    final subjects = state.subjects;
    final bool isEnrolled = state.isEnrolled;

    if (state.loadingLectures && lectures.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.lecturesError != null && lectures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CText(
            state.lecturesError!.message,
            type: TextType.bodyMedium,
            color: AppColors.failure,
          ),
        ),
      );
    }

    if (lectures.isEmpty) {
      return const Center(child: CText('No lectures available'));
    }

    const uncategorizedKey = '_uncategorized';
    final Map<String, List<LectureModel>> grouped = {
      for (final subject in subjects) subject.id: <LectureModel>[],
    };

    for (final lecture in lectures) {
      final key = lecture.subjectId != null && lecture.subjectId!.isNotEmpty
          ? lecture.subjectId!
          : uncategorizedKey;
      grouped.putIfAbsent(key, () => <LectureModel>[]).add(lecture);
    }

    final List<_LectureGroup> groups = [];
    for (final subject in subjects) {
      final entries = grouped.remove(subject.id);
      if (entries != null && entries.isNotEmpty) {
        groups.add(
          _LectureGroup(title: subject.subjectName, lectures: entries),
        );
      }
    }

    grouped.forEach((key, value) {
      if (value.isEmpty) return;
      final title = key == uncategorizedKey
          ? 'General Lectures'
          : 'Subject $key';
      groups.add(_LectureGroup(title: title, lectures: value));
    });

    // Use helper _openLecture to reduce rebuild allocations

    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray300, width: 1),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                backgroundColor: AppColors.white,
                collapsedBackgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: CText(group.title, type: TextType.titleMedium),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: group.lectures.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1, // square tiles
                          ),
                      itemBuilder: (ctx, i) {
                        final lecture = group.lectures[i];
                        return _LectureCard(
                          key: ValueKey(lecture.id ?? i),
                          lecture: lecture,
                          isEnrolled: isEnrolled,
                          onOpen: () =>
                              _openLecture(context, ref, lecture, isEnrolled),
                        );
                      },
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

  static String _lectureMeta(LectureModel lecture) {
    final parts = <String>[];
    if (lecture.durationSeconds != null) {
      parts.add(_formatDuration(lecture.durationSeconds!));
    }
    if (lecture.lecturerName != null && lecture.lecturerName!.isNotEmpty) {
      parts.add(lecture.lecturerName!);
    }
    if (lecture.viewCount != null) {
      parts.add('${lecture.viewCount} views');
    }
    return parts.isEmpty ? 'Tap to watch' : parts.join(' • ');
  }

  static String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    if (minutes >= 60) {
      final hours = duration.inHours;
      final remMinutes = minutes % 60;
      return '${hours}h ${remMinutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${remainingSeconds}s';
  }
}

Future<Map<String, String>?> _resolvePlaybackHeaders(
  WidgetRef ref,
  String watchUrl,
) async {
  final playbackUri = Uri.tryParse(watchUrl);
  final apiUri = Uri.tryParse(ApiEndPoints.baseUrl);

  if (playbackUri == null || apiUri == null) return null;
  if (playbackUri.host != apiUri.host) return null;

  // Signed URLs often include their own token/signature information and break when
  // the Authorization header is attached. Skip the header if we can detect a
  // signature-style query parameter.
  const signedQueryKeys = {
    'token',
    'signature',
    'expires',
    'x-amz-signature',
    'x-amz-security-token',
    'x-goog-signature',
  };
  final lowerCaseKeys = playbackUri.queryParameters.keys.map(
    (key) => key.toLowerCase(),
  );
  if (lowerCaseKeys.any(signedQueryKeys.contains)) {
    return null;
  }

  final token = await ref.read(secureStorageServiceProvider).read('token');
  if (token == null || token.isEmpty) return null;

  return {'Authorization': 'Bearer $token'};
}

class _LectureGroup {
  _LectureGroup({required this.title, required this.lectures});

  final String title;
  final List<LectureModel> lectures;
}

class _LectureCard extends StatelessWidget {
  const _LectureCard({
    Key? key,
    required this.lecture,
    required this.onOpen,
    required this.isEnrolled,
  }) : super(key: key);

  final LectureModel lecture;
  final VoidCallback onOpen;
  final bool isEnrolled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: lecture.thumbnailUrl != null
                    ? CustomCachedNetworkImage(
                        imageUrl: lecture.thumbnailUrl!,
                        fitStatus: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.primary.withOpacity(0.08),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CText(
                lecture.name,
                type: TextType.bodySmall,
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child:
                        (lecture.lecturerName != null &&
                            lecture.lecturerName!.isNotEmpty)
                        ? CText(
                            lecture.lecturerName!.substring(0, 1),
                            type: TextType.bodySmall,
                            color: AppColors.primary,
                          )
                        : const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 12,
                          ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CText(
                      lecture.lecturerName ?? 'Unknown',
                      type: TextType.bodySmall,
                      color: AppColors.gray700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isEnrolled
                          ? Icons.play_arrow_rounded
                          : Icons.lock_outline,
                    ),
                    color: isEnrolled ? AppColors.primary : AppColors.gray400,
                    onPressed: onOpen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
