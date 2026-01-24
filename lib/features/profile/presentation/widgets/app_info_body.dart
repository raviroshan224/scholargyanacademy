import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/models/app_info_model.dart';

class AppInfoBody extends StatelessWidget {
  final AppInfoContent content;
  final bool showHeaderImage;

  const AppInfoBody({
    super.key,
    required this.content,
    this.showHeaderImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final sections =
        content.sections.where((section) => section.hasContent).toList();
    final children = <Widget>[];

    if (showHeaderImage && content.hasImage) {
      children.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomCachedNetworkImage(
            imageUrl: content.imageUrl!,
            fitStatus: BoxFit.cover,
          ),
        ),
      );
      if (sections.isNotEmpty) {
        children.add(AppSpacing.verticalSpaceLarge);
      }
    }

    if (sections.isEmpty) {
      children.add(
        const CText(
          'Content will be available soon.',
          type: TextType.bodyMedium,
          color: AppColors.gray600,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      for (var sectionIndex = 0;
          sectionIndex < sections.length;
          sectionIndex++) {
        final section = sections[sectionIndex];

        if (section.hasTitle) {
          children.add(
            CText(
              section.title!,
              type: TextType.bodyLarge,
              color: AppColors.black,
            ),
          );
          children.add(AppSpacing.verticalSpaceSmall);
        }

        final paragraphs = section.paragraphs;
        for (var paragraphIndex = 0;
            paragraphIndex < paragraphs.length;
            paragraphIndex++) {
          children.add(
            CText(
              paragraphs[paragraphIndex],
              type: TextType.bodyMedium,
              color: AppColors.gray600,
            ),
          );
          if (paragraphIndex < paragraphs.length - 1) {
            children.add(AppSpacing.verticalSpaceSmall);
          }
        }

        if (sectionIndex < sections.length - 1) {
          children.add(AppSpacing.verticalSpaceLarge);
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }
}

class AppInfoError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppInfoError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CText(
              message,
              type: TextType.bodyMedium,
              color: AppColors.gray600,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpaceAverage,
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
