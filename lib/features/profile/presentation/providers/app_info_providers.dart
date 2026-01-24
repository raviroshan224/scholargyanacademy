import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/services/remote_services/http_service_provider.dart';
import '../../data/models/app_info_model.dart';
import '../../data/repo/app_info_repository.dart';

final appInfoRepositoryProvider = Provider<AppInfoRepository>((ref) {
  final httpService = ref.watch(httpServiceProvider);
  return AppInfoRepositoryImpl(httpService);
});

final aboutAppInfoProvider = FutureProvider<AppInfoContent>((ref) async {
  final repository = ref.watch(appInfoRepositoryProvider);
  final result = await repository.fetchAbout();
  return result.fold(
    (failure) => throw failure,
    (content) => content,
  );
});

final termsAppInfoProvider = FutureProvider<AppInfoContent>((ref) async {
  final repository = ref.watch(appInfoRepositoryProvider);
  final result = await repository.fetchTerms();
  return result.fold(
    (failure) => throw failure,
    (content) => content,
  );
});

final faqAppInfoProvider = FutureProvider<List<AppFaqItem>>((ref) async {
  final repository = ref.watch(appInfoRepositoryProvider);
  final result = await repository.fetchFaqs();
  return result.fold(
    (failure) => throw failure,
    (items) => items,
  );
});
