import 'package:dartz/dartz.dart';

import '../../../../config/services/remote_services/errors/failure.dart';
import '../../../../config/services/remote_services/http_service.dart';
import '../models/app_info_model.dart';

abstract class AppInfoRepository {
  Future<Either<Failure, AppInfoContent>> fetchAbout();
  Future<Either<Failure, AppInfoContent>> fetchTerms();
}

class AppInfoRepositoryImpl implements AppInfoRepository {
  final HttpService _httpService;

  AppInfoRepositoryImpl(this._httpService);

  @override
  Future<Either<Failure, AppInfoContent>> fetchAbout() async {
    return const Right(
      AppInfoContent(
        title: 'About Us',
        sections: [
          AppInfoSection(
            paragraphs: [
              'Welcome to our Academy, your trusted partner in online education. We are committed to providing a high-quality, accessible, and engaging learning experience for students and professionals. Our platform is built to empower learners at every stage of their journey through structured courses, expert guidance, and innovative tools.',
              'Our mission is to make education accessible to everyone, everywhere. We believe that with the right support, every learner has the potential to reach their academic and professional goals. We continuously curate and update our content to align with the latest standards and real-world needs.',
              'We offer an extensive range of subjects through interactive courses, recorded sessions, comprehensive study materials, and mock tests. Whether you are starting out or looking to advance, our platform is designed to support your growth every step of the way.',
            ],
          ),
        ],
      ),
    );
  }

  @override
  Future<Either<Failure, AppInfoContent>> fetchTerms() async {
    return const Right(
      AppInfoContent(
        title: 'Terms & Conditions',
        sections: [
          AppInfoSection(
            title: 'Acceptance of Terms',
            paragraphs: [
              'By accessing or using our platform, you agree to comply with and be bound by these Terms and Conditions. These terms govern your use of our website, mobile application, and associated services. If you do not agree with any part of these terms, please discontinue your use of our services immediately.',
            ],
          ),
          AppInfoSection(
            title: 'User Accounts',
            paragraphs: [
              'To access specific courses and personalised features, you must create a user account. You are fully responsible for maintaining the security of your account credentials and for all activity that takes place under your account. We reserve the right to suspend or remove accounts that violate our usage policies.',
            ],
          ),
          AppInfoSection(
            title: 'Intellectual Property',
            paragraphs: [
              'All content on this platform — including videos, study materials, mock tests, and interface designs — is our exclusive intellectual property. Unauthorised downloading, distribution, reproduction, or sharing of our content is strictly prohibited and may result in appropriate action.',
            ],
          ),
          AppInfoSection(
            title: 'Modifications to Service',
            paragraphs: [
              'We reserve the right to modify, suspend, or discontinue any part of our service at any time without prior notice. We may also update these terms periodically to reflect changes in our practice or legal requirements. Continued use of the platform following any updates constitutes your acceptance of the revised terms.',
            ],
          ),
        ],
      ),
    );
  }
}
