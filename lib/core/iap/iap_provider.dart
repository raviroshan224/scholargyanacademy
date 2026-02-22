import 'package:flutter_riverpod/legacy.dart';

import 'iap_controller_ios.dart';

final iapControllerProvider = ChangeNotifierProvider<IapController>((ref) {
  return IapController();
});
