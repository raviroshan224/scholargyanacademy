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
          borderRadius: BorderRadius.circular(16),
          child: CustomCachedNetworkImage(
            imageUrl: content.imageUrl!,
            fitStatus: BoxFit.cover,
            size: const Size(double.infinity, 200),
          ),
        ),
      );
      if (sections.isNotEmpty) {
        children.add(AppSpacing.verticalSpaceLarge);
      }
    }

    if (sections.isEmpty) {
      children.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.article_outlined, size: 56, color: AppColors.gray300),
                SizedBox(height: 20),
                CText(
                  'Content will be updated soon.',
                  type: TextType.bodyLarge,
                  color: AppColors.gray500,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      for (var sectionIndex = 0;
          sectionIndex < sections.length;
          sectionIndex++) {
        final section = sections[sectionIndex];
        final sectionWidgets = <Widget>[];

        if (section.hasTitle) {
          sectionWidgets.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 22,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: CText(
                    section.title!,
                    type: TextType.titleMedium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900 ?? AppColors.black,
                  ),
                ),
              ],
            ),
          );
          sectionWidgets.add(const SizedBox(height: 14));
        }

        final paragraphs = section.paragraphs;
        for (var i = 0; i < paragraphs.length; i++) {
          sectionWidgets.add(
            Text(
              paragraphs[i],
              style: const TextStyle(
                fontSize: 14,
                height: 1.75,
                color: Color(0xFF555F6D),
                letterSpacing: 0.1,
              ),
            ),
          );
          if (i < paragraphs.length - 1) {
            sectionWidgets.add(const SizedBox(height: 14));
          }
        }

        children.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFECEFF1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sectionWidgets,
            ),
          ),
        );

        if (sectionIndex < sections.length - 1) {
          children.add(const SizedBox(height: 16));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
