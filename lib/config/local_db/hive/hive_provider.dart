import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hive_data_source.dart';

final hiveDataSourceProvider = Provider<HiveDataSource>((Ref ref) {
  return HiveDataSource();
  // Reuse singleton instance
});
