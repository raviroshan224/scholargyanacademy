import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';
import 'package:scholarsgyanacademy/features/dashboard/presentation/pages/dashboard.dart';

import '../../../../core/core.dart';
import '../../../profile/presentation/providers/favorite_category_notifier.dart';
import '../../../profile/presentation/providers/providers.dart';
import '../widgets/course_selection_expansion.dart';

class CourseSelection extends ConsumerWidget {
  final bool? fromLogin;
  CourseSelection({super.key, this.userName, this.fromLogin = true});
  final String? userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoriteCategoryNotifierProvider);
    final notifier = ref.read(favoriteCategoryNotifierProvider.notifier);

    ref.listen<FavoriteCategoryState>(favoriteCategoryNotifierProvider, (
      previous,
      next,
    ) {
      if (next.isUpdateSuccessful) {
        ref.read(authNotifierProvider.notifier).getMe();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
          (route) => false,
        );
      }
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: fromLogin == false
          ? CustomAppBar(title: "Preferred Categories")
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fromLogin!) ...[
                CText(
                  "Namaste ${userName ?? AppStrings.userName}",
                  type: TextType.headlineLarge,
                ),
                AppSpacing.verticalSpaceSmall,
                const CText(
                  'Please Select the course you are interested in',
                  type: TextType.bodyMedium,
                ),
                AppSpacing.verticalSpaceLarge,
              ],
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (state.error != null && state.categoryHierarchy.isEmpty)
                Center(child: Text('Error: ${state.error}'))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: state.categoryHierarchy.length,
                    separatorBuilder: (context, index) =>
                        AppSpacing.verticalSpaceAverage,
                    itemBuilder: (context, index) {
                      final parent = state.categoryHierarchy[index];
                      return CourseSelectionItem(
                        title: parent.parentCategory.categoryName,
                        subtitle: "${parent.childCategories.length} Courses",
                        svgPath: parent.parentCategory.categoryImageUrl ?? null,
                        childCategories: parent.childCategories,
                        onTap: (categoryId) {
                          if (parent.childCategories.any(
                            (child) => child.id == categoryId,
                          )) {
                            notifier.toggleCategory(categoryId);
                          }
                        },
                        initiallyExpanded: index == 0,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 20, right: 20, left: 20),
        child: ReusableButton(
          text: "Next",
          onPressed: () async {
            await notifier.updateFavoriteCategories();
          },
          isLoading: state.isUpdating,
        ),
      ),
    );
  }
}
