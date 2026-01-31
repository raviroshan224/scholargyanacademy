import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/core.dart';
import '../../../courses/courses.dart';
import '../../../profile/presentation/pages/detail _pages/checkout_page.dart';
import '../widgets/explore_tab_bar.dart';

final selectedTabIndexProvider = StateProvider<int>((Ref ref) => 0);

class CourseDetailsPage extends ConsumerWidget {
  const CourseDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTabIndex = ref.watch(selectedTabIndexProvider);

    final List<String> tabTitles = ["Syllabus", "Whats included", "Lecturers"];
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(80.0),
        child: DefaultTabController(
          length: tabTitles.length,
          child: ListView(
            children: [
              CustomCachedNetworkImage(imageUrl: AppAssets.dummyNetImg),
              AppSpacing.verticalSpaceMedium,
              CText(AppStrings.userName, type: TextType.titleLarge),
              AppSpacing.verticalSpaceSmall,
              CText(AppStrings.ncourse, type: TextType.labelSmall),
              AppSpacing.verticalSpaceMedium,
              CText(
                'AVenenatis feugiat ullamcorper varius donec venenatis orci eget pulvinar. Suspendisse ac pellentesque nullam sit velit. Faucibus adipiscing netus nisl odio. Tristique sapien et erat quis commodo fringilla. Volutpat mauris euismod venenatis',
                type: TextType.labelSmall,
              ),
              AppSpacing.verticalSpaceMedium,

              TabBar(
                indicatorColor: AppColors.white,
                onTap: (index) {
                  ref.read(selectedTabIndexProvider.notifier).state = index;
                },
                unselectedLabelColor: AppColors.gray800,
                isScrollable: true,
                indicator: null,
                tabAlignment: TabAlignment.start,
                tabs: tabTitles
                    .map(
                      (title) => Card(
                        elevation: 8,
                        color: Colors.transparent,
                        child: ExploreTabContainer(
                          text: title,
                          isSelected:
                              selectedTabIndex == tabTitles.indexOf(title),
                        ),
                      ),
                    )
                    .toList(),
              ),

              // Tab View
              IndexedStack(
                index: selectedTabIndex,
                children: [SyllabusInfo(), WhatsIncluded(), LecturersInfo()],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(left: 4.0, right: 4.0, bottom: 16.0),
        child: Container(
          color: AppColors.white,
          child: Row(
            children: [
              AppSpacing.horizontalSpaceLarge,
              CText(" Rs. 4000", type: TextType.headlineMedium),
              Spacer(),
              ReusableButton(
                text: "Enroll Now",
                backgroundColor: AppColors.secondary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CheckoutPage()),
                  );
                },
              ),
              AppSpacing.horizontalSpaceLarge,
            ],
          ),
        ),
      ),
    );
  }
}
