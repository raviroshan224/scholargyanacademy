import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../../../core/core.dart';
import '../../../explore/explore.dart';
import '../../courses.dart';

final selectedTabIndexProvider = StateProvider<int>((Ref ref) => 0);

class CoursePage extends ConsumerWidget {
  const CoursePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> tabTitles = ['My Courses', 'Ongoing Classes'];
    final selectedTabIndex = ref.watch(selectedTabIndexProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: "Courses Enrolled"),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Pill-style tab switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: tabTitles.map((title) {
                final index = tabTitles.indexOf(title);
                final isSelected = selectedTabIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedTabIndexProvider.notifier).state = index;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: index == 0 ? 8 : 0,
                        left: index == 1 ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1E3A5F) // Dark blue
                            : AppColors.gray200, // Light gray
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: CText(
                        title,
                        type: TextType.bodyMedium,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.white : AppColors.gray700,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: IndexedStack(
              index: selectedTabIndex,
              children: [
                MyCourses(),
                OngoingClassList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
