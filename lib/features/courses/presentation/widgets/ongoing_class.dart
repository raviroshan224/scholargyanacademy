import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scholarsgyanacademy/features/courses/view_model/live_class_join_view_model.dart';

import '../../../../core/core.dart';
import '../../model/live_class_models.dart';
import '../../view_model/course_view_model.dart';


class OngoingClassList extends ConsumerStatefulWidget {
  const OngoingClassList({super.key});

  @override
  ConsumerState<OngoingClassList> createState() => _OngoingClassListState();
}

class _OngoingClassListState extends ConsumerState<OngoingClassList> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(coursesViewModelProvider.notifier)
          .fetchLiveClasses(force: true, status: 'ongoing');
    });
    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      ref.read(coursesViewModelProvider.notifier).loadMoreLiveClasses();
    }
  }

  Future<void> _refresh() async {
    await ref
        .read(coursesViewModelProvider.notifier)
        .fetchLiveClasses(force: true, status: 'ongoing');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coursesViewModelProvider);
    final classes = state.liveClasses;
    final isLoading = state.loadingLiveClasses;
    final failure = state.liveClassesError;

    // CRITICAL: Listen for join state changes and navigate to MeetingPage
    ref.listen<LiveClassJoinState>(liveClassJoinViewModelProvider, (
      previous,
      next,
    ) {
      debugPrint(
        '🔍 [OngoingClass Listener] State: ${previous?.status} -> ${next.status}',
      );
      debugPrint(
        '🔍 [OngoingClass Listener] Token: ${next.token != null ? "present" : "null"}',
      );
      debugPrint(
        '🔍 [OngoingClass Listener] ProcessingClassId: ${next.processingClassId}',
      );

      if (!mounted) return;

      // Navigate to MeetingPage when joining starts
      if (next.status == LiveClassJoinStatus.joining &&
          previous?.status != LiveClassJoinStatus.joining &&
          next.token != null) {
        
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Live classes are currently unavailable in this version.')),
          );
      }

      // Handle join failure
      if (next.status == LiveClassJoinStatus.failure &&
          previous?.status != LiveClassJoinStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Failed to join live class'),
            backgroundColor: AppColors.failure,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    Widget buildContent() {
      if (isLoading && classes.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (failure != null && classes.isEmpty) {
        return ListView(
          controller: _controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.failure),
            AppSpacing.verticalSpaceMedium,
            CText(
              failure.message,
              type: TextType.bodyLarge,
              textAlign: TextAlign.center,
              color: AppColors.failure,
            ),
            AppSpacing.verticalSpaceMedium,
            ReusableButton(text: 'Retry', onPressed: _refresh),
          ],
        );
      }

      if (classes.isEmpty) {
        return ListView(
          controller: _controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 48,
              color: AppColors.gray500,
            ),
            AppSpacing.verticalSpaceMedium,
            const CText(
              'No live classes are running right now.',
              type: TextType.bodyLarge,
              textAlign: TextAlign.center,
              color: AppColors.gray700,
            ),
            AppSpacing.verticalSpaceMedium,
            const CText(
              'Check back soon or explore upcoming sessions.',
              type: TextType.bodySmall,
              textAlign: TextAlign.center,
              color: AppColors.gray600,
            ),
          ],
        );
      }

      return ListView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 120.0),
        itemCount: classes.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= classes.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = classes[index];
          return _LiveClassCard(
            liveClass: item,
            onJoin: () {
              ref
                  .read(liveClassJoinViewModelProvider.notifier)
                  .joinLiveClass(item.id);
            },
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: buildContent(),
      ),
    );
  }
}

class _LiveClassCard extends StatelessWidget {
  final LiveClassModel liveClass;
  final VoidCallback onJoin;

  const _LiveClassCard({required this.liveClass, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final subtitle = liveClass.subjectName ?? liveClass.courseTitle ?? 'Live';
    final instructor = liveClass.lecturerName ?? 'Instructor';
    final timeLabel = _formatSchedule(liveClass);
    final bannerUrl = liveClass.bannerImageUrl ?? AppAssets.dummyNetImg;
    final statusLabel = _statusLabel(liveClass.status);
    final canJoin = liveClass.isJoinable; // calculated from time

    ImageProvider provider;
    if (liveClass.lecturerImageUrl != null &&
        liveClass.lecturerImageUrl!.isNotEmpty) {
      provider = NetworkImage(liveClass.lecturerImageUrl!);
    } else {
      provider = AssetImage(AppAssets.loginBg);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image with Join Now button
          Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomCachedNetworkImage(
                    imageUrl: bannerUrl,
                    fitStatus: BoxFit.cover,
                  ),
                ),
              ),
              if (statusLabel != null)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CText(
                      statusLabel,
                      type: TextType.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              Positioned(
                right: 12,
                bottom: 12,
                child: ElevatedButton(
                  onPressed: () {
                    print(
                      '🟢 Join Now clicked | canJoin=$canJoin | classId=${liveClass.id}',
                    );
                    onJoin();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const CText(
                    'Join Now',
                    type: TextType.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category/Subject
          CText(subtitle, type: TextType.bodySmall, color: AppColors.gray600),
          const SizedBox(height: 4),

          // Title
          CText(
            liveClass.title,
            type: TextType.bodyLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Duration
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppColors.gray600),
              const SizedBox(width: 6),
              CText(
                timeLabel,
                type: TextType.bodySmall,
                color: AppColors.gray600,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Instructor
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundImage: provider),
              const SizedBox(width: 8),
              CText(
                instructor,
                type: TextType.bodySmall,
                color: AppColors.gray700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatSchedule(LiveClassModel liveClass) {
    final start = liveClass.startTime;
    final end = liveClass.endTime;
    final formatter = DateFormat('MMM d • hh:mm a');
    final shortTime = DateFormat('hh:mm a');

    if (start != null && end != null) {
      final sameDay =
          start.year == end.year &&
          start.month == end.month &&
          start.day == end.day;
      if (sameDay) {
        return '${formatter.format(start)} - ${shortTime.format(end)}';
      }
      return '${formatter.format(start)} - ${formatter.format(end)}';
    }
    if (start != null) {
      return 'Starts ${formatter.format(start)}';
    }
    if (liveClass.durationLabel != null &&
        liveClass.durationLabel!.isNotEmpty) {
      return liveClass.durationLabel!;
    }
    if (liveClass.durationMinutes != null) {
      return '${liveClass.durationMinutes} min session';
    }
    return 'Live session';
  }

  static String? _statusLabel(String? status) {
    if (status == null) return null;
    switch (status.toLowerCase()) {
      case 'ongoing':
      case 'live':
        return 'Live now';
      case 'upcoming':
        return 'Starts soon';
      case 'completed':
      case 'past':
        return 'Completed';
      default:
        return null;
    }
  }
}
