import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../model/live_class_models.dart';
import '../../view_model/live_class_join_view_model.dart';
import 'meeting_page.dart';
import 'meeting_page_v2.dart'; // ✅ NEW: Production-grade meeting UI

class LiveClassDetailPage extends ConsumerStatefulWidget {
  const LiveClassDetailPage({
    super.key,
    required this.liveClass,
  });

  final LiveClassModel liveClass;

  @override
  ConsumerState<LiveClassDetailPage> createState() =>
      _LiveClassDetailPageState();
}

class _LiveClassDetailPageState extends ConsumerState<LiveClassDetailPage> {
  @override
  Widget build(BuildContext context) {
    final joinState = ref.watch(liveClassJoinViewModelProvider);
    final joinNotifier = ref.read(liveClassJoinViewModelProvider.notifier);

    // Listen to join state changes for UX feedback
    ref.listen<LiveClassJoinState>(
      liveClassJoinViewModelProvider,
      (previous, next) {
        debugPrint('🔍 [UI Listener] State: ${previous?.status} -> ${next.status}');
        debugPrint('🔍 [UI Listener] Token: ${next.token != null ? "present" : "null"}');
        debugPrint('🔍 [UI Listener] ProcessingClassId: ${next.processingClassId}');
        if (!mounted) return;

        // FIX: Navigate to MeetingPage when joining starts (not when joined)
        // This ensures event listeners are set up BEFORE Zoom SDK fires events
        if (next.status == LiveClassJoinStatus.joining &&
            previous?.status != LiveClassJoinStatus.joining &&
            next.token != null) {
          debugPrint('🚀 [UI] Navigating to MeetingPageV2 BEFORE join completes...');
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            
            // Navigate with the join token so MeetingPageV2 can complete the join
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MeetingPageV2( // ✅ SWITCHED TO V2
                  token: next.token!,
                  classId: next.processingClassId ?? '',
                ),
              ),
            ).then((_) {
              // Reset state when returning from meeting
              joinNotifier.reset();
            });
          });
        }

        // Handle join failure
        if (next.status == LiveClassJoinStatus.failure &&
            previous?.status != LiveClassJoinStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage ?? 'Failed to join live class'),
              backgroundColor: AppColors.failure,
              duration: const Duration(seconds: 4),
              action: next.errorMessage?.toLowerCase().contains('permission') == true
                ? SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () => joinNotifier.openAppSettingsRequest(),
                  )
                : null,
            ),
          );
        }
      },
    );

    final liveClass = widget.liveClass;

    // CRITICAL: Use calculated status, NOT backend status
    // Backend often returns "scheduled" even for ongoing classes
    final actualStatus = liveClass.calculateActualStatus();
    final isOngoing = actualStatus == 'ongoing';
    final isUpcoming = actualStatus == 'upcoming';
    final isEnded = actualStatus == 'ended';

    print(
        '🔍 [STATUS CHECK] Backend status: ${liveClass.status}, Calculated: $actualStatus');

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: liveClass.title,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            if (liveClass.bannerImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  liveClass.bannerImageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: AppColors.gray200,
                      child: const Icon(
                        Icons.video_library,
                        size: 64,
                        color: AppColors.gray400,
                      ),
                    );
                  },
                ),
              ),

            AppSpacing.verticalSpaceLarge,

            // Status Badge - use calculated status
            _StatusBadge(status: actualStatus),

            AppSpacing.verticalSpaceMedium,

            // Title
            CText(
              liveClass.title,
              type: TextType.headlineMedium,
              fontWeight: FontWeight.bold,
            ),

            AppSpacing.verticalSpaceSmall,

            // Course & Subject Info
            if (liveClass.courseTitle != null)
              Row(
                children: [
                  const Icon(Icons.school, size: 16, color: AppColors.gray600),
                  AppSpacing.horizontalSpaceSmall,
                  Expanded(
                    child: CText(
                      liveClass.courseTitle!,
                      type: TextType.bodyMedium,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),

            if (liveClass.subjectName != null) ...[
              AppSpacing.verticalSpaceSmall,
              Row(
                children: [
                  const Icon(Icons.book, size: 16, color: AppColors.gray600),
                  AppSpacing.horizontalSpaceSmall,
                  Expanded(
                    child: CText(
                      liveClass.subjectName!,
                      type: TextType.bodyMedium,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ],

            AppSpacing.verticalSpaceLarge,

            // Lecturer Info
            if (liveClass.lecturerName != null)
              _LecturerCard(
                name: liveClass.lecturerName!,
                imageUrl: liveClass.lecturerImageUrl,
              ),

            AppSpacing.verticalSpaceLarge,

            // Schedule Info
            _ScheduleCard(
              startTime: liveClass.startTime,
              endTime: liveClass.endTime,
              durationLabel: liveClass.durationLabel,
            ),

            AppSpacing.verticalSpaceLarge,

            // Description
            if (liveClass.description != null) ...[
              const CText(
                'Description',
                type: TextType.headlineSmall,
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpaceSmall,
              CText(
                liveClass.description!,
                type: TextType.bodyMedium,
                color: AppColors.gray700,
              ),
              AppSpacing.verticalSpaceLarge,
            ],

            // Join Button (only for ongoing classes)
            if (isOngoing)
              SizedBox(
                width: double.infinity,
                child: ReusableButton(
                  text: joinState.isWaitingForHost
                      ? 'Waiting for Lecturer...'
                      : 'Join Live Class',
                  isLoading: joinState.isLoading,
                  onPressed: joinState.isInMeeting
                      ? null // Disable if already in meeting
                      : () {
                          print(
                              '🟢 [UI] Join button pressed for classId=${liveClass.id}');
                          joinNotifier.joinLiveClass(liveClass.id);
                        },
                ),
              ),

            // Upcoming message
            if (isUpcoming)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.primary),
                    AppSpacing.horizontalSpaceMedium,
                    Expanded(
                      child: CText(
                        'This class hasn\'t started yet. Please join at the scheduled time.',
                        type: TextType.bodyMedium,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

            // Ended message
            if (isEnded)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.gray600),
                    AppSpacing.horizontalSpaceMedium,
                    const Expanded(
                      child: CText(
                        'This class has ended.',
                        type: TextType.bodyMedium,
                        color: AppColors.gray700,
                      ),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    final statusLower = status!.toLowerCase();
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (statusLower) {
      case 'ongoing':
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        icon = Icons.circle;
        break;
      case 'upcoming':
        backgroundColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        icon = Icons.schedule;
        break;
      case 'ended':
        backgroundColor = AppColors.gray200;
        textColor = AppColors.gray600;
        icon = Icons.check_circle;
        break;
      default:
        backgroundColor = AppColors.gray200;
        textColor = AppColors.gray600;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          AppSpacing.horizontalSpaceSmall,
          CText(
            status!.toUpperCase(),
            type: TextType.bodySmall,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}

class _LecturerCard extends StatelessWidget {
  const _LecturerCard({
    required this.name,
    this.imageUrl,
  });

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.gray100,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              backgroundImage:
                  imageUrl != null ? NetworkImage(imageUrl!) : null,
              child: imageUrl == null
                  ? const Icon(Icons.person, color: AppColors.white)
                  : null,
            ),
            AppSpacing.horizontalSpaceMedium,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CText(
                    'Lecturer',
                    type: TextType.bodySmall,
                    color: AppColors.gray600,
                  ),
                  CText(
                    name,
                    type: TextType.bodyMedium,
                    fontWeight: FontWeight.w600,
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    this.startTime,
    this.endTime,
    this.durationLabel,
  });

  final DateTime? startTime;
  final DateTime? endTime;
  final String? durationLabel;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      elevation: 0,
      color: AppColors.gray100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CText(
              'Schedule',
              type: TextType.bodyMedium,
              fontWeight: FontWeight.bold,
            ),
            AppSpacing.verticalSpaceSmall,
            if (startTime != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppColors.gray600),
                  AppSpacing.horizontalSpaceSmall,
                  CText(
                    dateFormat.format(startTime!),
                    type: TextType.bodyMedium,
                    color: AppColors.gray700,
                  ),
                ],
              ),
              AppSpacing.verticalSpaceSmall,
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 16, color: AppColors.gray600),
                  AppSpacing.horizontalSpaceSmall,
                  CText(
                    '${timeFormat.format(startTime!)}${endTime != null ? ' - ${timeFormat.format(endTime!)}' : ''}',
                    type: TextType.bodyMedium,
                    color: AppColors.gray700,
                  ),
                ],
              ),
            ],
            if (durationLabel != null) ...[
              AppSpacing.verticalSpaceSmall,
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: AppColors.gray600),
                  AppSpacing.horizontalSpaceSmall,
                  CText(
                    durationLabel!,
                    type: TextType.bodyMedium,
                    color: AppColors.gray700,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
