import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/services/remote_services/errors/failure.dart';
import '../../../../../core/core.dart';
import '../../providers/app_info_providers.dart';
import '../../widgets/app_info_body.dart';

class TermsAndConditions extends ConsumerWidget {
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContent = ref.watch(termsAppInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Terms & Conditions',
      ),
      body: asyncContent.when(
        data: (content) => AppInfoBody(
          content: content,
          showHeaderImage: false,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppInfoError(
          message: error is Failure
              ? error.message
              : 'Failed to load terms and conditions.',
          onRetry: () => ref.invalidate(termsAppInfoProvider),
        ),
      ),
    );
  }
}
