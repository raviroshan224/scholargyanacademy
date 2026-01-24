import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_keys.dart';


class HiveSetup {
  HiveSetup._();

  /// Initializes Hive database
  static Future get initHive => initializeHive();

  static Future<void> initializeHive() async {
    try {
      await Hive.initFlutter();
      log('✅ Hive initialized successfully');

      // Pre-open the auth box
      final authBox = await Hive.openLazyBox(HIVE_TOKEN_BOX);
      log('📦 Auth box opened successfully - Box length: ${authBox.length}');
    } catch (e) {
      log('❌ Error initializing Hive: $e');
      rethrow;
    }
  }


}



