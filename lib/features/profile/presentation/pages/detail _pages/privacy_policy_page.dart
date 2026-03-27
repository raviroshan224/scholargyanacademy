import 'package:flutter/material.dart';
import 'package:scholarsgyanacademy/features/profile/data/models/app_info_model.dart';

import '../../../../../core/core.dart';
import '../../widgets/app_info_body.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    const privacyContent = AppInfoContent(
      title: 'Privacy Policy',
      sections: [
        AppInfoSection(
          title: 'Information We Collect',
          paragraphs: [
            'We collect personal information such as your name, email address, and phone number when you create an account on our platform. In addition, we collect usage data including your learning progress and activity within the application. This information helps us provide a more personalised and relevant experience for every user.',
          ],
        ),
        AppInfoSection(
          title: 'How We Use Your Information',
          paragraphs: [
            'The information we collect is used to personalise your learning journey, provide timely customer support, and communicate important updates about our services. We may use anonymised data to analyse trends, improve our platform, and develop new features that better serve our community of learners.',
          ],
        ),
        AppInfoSection(
          title: 'Data Sharing and Disclosure',
          paragraphs: [
            'We do not sell, trade, or rent your personal information to third parties. We may share anonymised, aggregated data for analytical purposes. In cases where disclosure is required by law or to protect user safety, we may share relevant information with appropriate authorities in accordance with applicable regulations.',
          ],
        ),
        AppInfoSection(
          title: 'Data Security',
          paragraphs: [
            'We take data protection seriously and implement appropriate technical and organisational security measures to protect your personal information against unauthorised access, alteration, disclosure, or destruction. All data is transmitted over encrypted connections, and access is strictly limited to authorised personnel only.',
          ],
        ),
        AppInfoSection(
          title: 'Changes to This Policy',
          paragraphs: [
            'We may update this Privacy Policy from time to time to reflect changes in our practices or for legal, operational, or regulatory reasons. We encourage you to review this page periodically. Your continued use of our platform following any changes indicates your acceptance of the updated policy.',
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: 'Privacy Policy'),
      body: const AppInfoBody(content: privacyContent, showHeaderImage: false),
    );
  }
}
