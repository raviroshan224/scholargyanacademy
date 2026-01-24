import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/services/remote_services/errors/failure.dart';
import '../../../../../core/core.dart';
import '../../providers/app_info_providers.dart';
import '../../widgets/app_info_body.dart';
import '../../../profile.dart';

class FAQPage extends ConsumerWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFaqs = ref.watch(faqAppInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'FAQ',
      ),
      body: asyncFaqs.when(
        data: (faqs) {
          if (faqs.isEmpty) {
            return const Center(
              child: CText(
                'FAQs will be available soon.',
                type: TextType.bodyMedium,
                color: AppColors.gray600,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final item = faqs[index];
              final answer = item.hasAnswer
                  ? item.answer
                  : 'We will update this answer soon.';
              return CustomExpansionTile(
                title: item.question,
                content: answer,
              );
            },
            separatorBuilder: (context, index) =>
                AppSpacing.verticalSpaceAverage,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => AppInfoError(
          message: error is Failure
              ? error.message
              : 'Failed to load frequently asked questions.',
          onRetry: () => ref.invalidate(faqAppInfoProvider),
        ),
      ),
    );
  }
}
