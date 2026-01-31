import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../dashboard/presentation/pages/dashboard.dart';

class MajorCourseSelection extends StatelessWidget {
  const MajorCourseSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        actions: [
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                CText("Skip", type: TextType.labelMedium),
                AppSpacing.horizontalSpaceSmall,
                Icon(Icons.arrow_forward_ios),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CText('Hey Kate', type: TextType.headlineMedium),
                AppSpacing.verticalSpaceMedium,
                const CText(
                  'Please Select the course you are interested in.',
                  type: TextType.titleLarge,
                ),
                AppSpacing.verticalSpaceMedium,
                ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: 3,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.gray300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CText(
                                "Government Exams in Nepal",
                                type: TextType.titleMedium,
                              ),
                              Spacer(),
                              Icon(Icons.check_box_outline_blank),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                AppSpacing.verticalSpaceVeryLarge,
              ],
            ),
            Positioned(
              bottom: 30,
              right: 4,
              left: 4,
              child: Container(
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ReusableButton(
                    text: "Next",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Dashboard()),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
