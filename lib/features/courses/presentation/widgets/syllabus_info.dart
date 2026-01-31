import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../model/course_models.dart';
import '../../view_model/course_view_model.dart';

class SyllabusInfo extends ConsumerWidget {
  const SyllabusInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coursesViewModelProvider);
    final subjects = state.subjects;

    if (state.loadingSubjects && subjects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.subjectsError != null && subjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CText(
            state.subjectsError!.message,
            type: TextType.bodyMedium,
            color: AppColors.failure,
          ),
        ),
      );
    }

    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: AppColors.gray300),
            const SizedBox(height: 12),
            const CText(
              'No syllabus available',
              type: TextType.titleMedium,
              color: AppColors.gray500,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: subjects.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _SubjectCard(subject: subject, index: index);
      },
    );
  }
}

class _SubjectCard extends StatefulWidget {
  const _SubjectCard({required this.subject, required this.index});

  final SubjectModel subject;
  final int index;

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconRotation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.subject.chapters;
    final hasChapters = chapters.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded ? AppColors.primary : AppColors.gray200,
          width: _isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isExpanded
                ? AppColors.primary.withOpacity(0.12)
                : Colors.black.withOpacity(0.06),
            blurRadius: _isExpanded ? 20 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: hasChapters ? _toggleExpanded : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject Number Badge
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isExpanded
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CText(
                          '${widget.index + 1}',
                          type: TextType.labelLarge,
                          color: _isExpanded
                              ? AppColors.white
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CText(
                              widget.subject.subjectName,
                              type: TextType.titleLarge,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                              maxLines: 7,
                              letterSpacing: -0.3,
                            ),
                            if (widget.subject.subjectDescription != null &&
                                widget.subject.subjectDescription!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              CText(
                                widget.subject.subjectDescription!,
                                type: TextType.bodySmall,
                                color: AppColors.gray600,
                                maxLines: _isExpanded ? 20 : 2,
                                overflow: TextOverflow.ellipsis,
                                height: 1.4,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Chapters Count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            CText(
                              '${chapters.length} ${chapters.length == 1 ? 'Chapter' : 'Chapters'}',
                              type: TextType.labelMedium,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                      // Mark Weight
                      if (widget.subject.markWeight != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              CText(
                                '${widget.subject.markWeight} Marks',
                                type: TextType.labelMedium,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      // Expand Icon
                      if (hasChapters)
                        RotationTransition(
                          turns: _iconRotation,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _isExpanded
                                ? AppColors.primary
                                : AppColors.gray500,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Chapters List
          if (_isExpanded)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  Divider(height: 1, color: AppColors.gray200),
                  if (chapters.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gray200,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: AppColors.gray400,
                            ),
                            const SizedBox(height: 8),
                            const CText(
                              'No chapters available yet',
                              type: TextType.bodyMedium,
                              color: AppColors.gray600,
                              textAlign: TextAlign.center,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: chapters.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: AppColors.gray100,
                        indent: 56,
                      ),
                      itemBuilder: (context, index) => _ChapterItem(
                        index: index,
                        chapter: chapters[index],
                        totalChapters: chapters.length,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChapterItem extends StatelessWidget {
  const _ChapterItem({
    required this.index,
    required this.chapter,
    required this.totalChapters,
  });

  final int index;
  final ChapterModel chapter;
  final int totalChapters;

  void _showChapterDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CText(
                            chapter.chapterTitle,
                            type: TextType.titleLarge,
                            fontWeight: FontWeight.w600,
                            maxLines: 7,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.gray700,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.gray200),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const CText(
                          'CHAPTER OVERVIEW',
                          type: TextType.labelSmall,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CText(
                        chapter.chapterDescription?.trim().isNotEmpty == true
                            ? chapter.chapterDescription!
                            : 'No detailed description available for this chapter. Please check back later for updated content.',
                        type: TextType.bodyMedium,
                        color: AppColors.gray800,
                        height: 1.6,
                        maxLines: 100,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showChapterDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Chapter Number
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: CText(
                  '${index + 1}',
                  type: TextType.labelMedium,
                  color: AppColors.gray700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              // Chapter Title
              Expanded(
                child: CText(
                  chapter.chapterTitle,
                  type: TextType.bodyMedium,
                  color: AppColors.gray800,
                  fontWeight: FontWeight.w400,
                  maxLines: 4,
                  height: 1.4,
                ),
              ),
              const SizedBox(width: 12),
              // Arrow Icon
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.gray400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
