import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/services/remote_services/errors/failure.dart';
import '../../../../../core/core.dart';
import '../../providers/app_info_providers.dart';
import '../../widgets/app_info_body.dart';

class AboutUsPage extends ConsumerWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContent = ref.watch(aboutAppInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'About Us',
      ),
      body: asyncContent.when(
        data: (content) => AppInfoBody(
          content: content,
          showHeaderImage: content.hasImage,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppInfoError(
          message: error is Failure
              ? error.message
              : 'Failed to load About Us content.',
          onRetry: () => ref.invalidate(aboutAppInfoProvider),
        ),
      ),
    );
  }
}
