import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/services/remote_services/errors/failure.dart';
import '../../../../core/constant/app_assets.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../../../core/utils/ui_helper/app_spacing.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/buttons/reusable_buttons.dart';
import '../../../../core/widgets/images/cached_image.dart';
import '../../../../core/widgets/text/custom_text.dart';
import '../../model/live_class_models.dart';
import '../../view_model/course_view_model.dart';

class UpcomingLiveClassesPage extends ConsumerStatefulWidget {
  const UpcomingLiveClassesPage({super.key});

  @override
  ConsumerState<UpcomingLiveClassesPage> createState() =>
      _UpcomingLiveClassesPageState();
}

class _UpcomingLiveClassesPageState
    extends ConsumerState<UpcomingLiveClassesPage> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(coursesViewModelProvider.notifier)
          .fetchUpcomingLiveClasses(force: true);
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
      ref.read(coursesViewModelProvider.notifier).loadMoreUpcomingLiveClasses();
    }
  }

  Future<void> _refresh() async {
    await ref
        .read(coursesViewModelProvider.notifier)
        .fetchUpcomingLiveClasses(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coursesViewModelProvider);
    final classes = state.upcomingLiveClasses;
    final isLoading = state.loadingUpcomingLiveClasses;
    final failure = state.upcomingLiveClassesError;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: 'Upcoming Classes'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildContent(classes, isLoading, failure),
      ),
    );
  }

  Widget _buildContent(
    List<LiveClassModel> classes,
    bool isLoading,
    Failure? failure,
  ) {
    if (isLoading && classes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (failure != null && classes.isEmpty) {
      return ListView(
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: AppColors.gray500,
          ),
          AppSpacing.verticalSpaceMedium,
          const CText(
            'No upcoming classes scheduled.',
            type: TextType.bodyLarge,
            textAlign: TextAlign.center,
            color: AppColors.gray700,
          ),
          AppSpacing.verticalSpaceMedium,
          const CText(
            'Check back later for new sessions.',
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: classes.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= classes.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _UpcomingClassCard(liveClass: classes[index]);
      },
    );
  }
}

class _UpcomingClassCard extends StatelessWidget {
  final LiveClassModel liveClass;

  const _UpcomingClassCard({required this.liveClass});

  @override
  Widget build(BuildContext context) {
    final subtitle = liveClass.subjectName ?? liveClass.courseTitle ?? 'Live';
    final instructor = liveClass.lecturerName ?? 'Instructor';
    final timeLabel = _formatSchedule(liveClass);
    final bannerUrl = liveClass.bannerImageUrl ?? AppAssets.dummyNetImg;

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
          // Banner Image
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

          // Duration / Time
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.gray600,
              ),
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

  String _formatSchedule(LiveClassModel liveClass) {
    final start = liveClass.startTime;
    if (start != null) {
      return 'Starts ${DateTimeHelper.formatForUI(start)}';
    }
    return 'Schedule to be announced';
  }
}
