// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/foundation.dart';
//
// import 'notification/handle_notifications.dart';
// import 'notification/local_notification_manager.dart';
//

import 'notification/local_notification_manager.dart';

class DependencyInjection {
  static Future<void> init() async {
    // Preserve the splash screen until the app is initialized.

    await initializeNotification();

    /// Initialize Crashlytics
    // handleCrashAnalytics();
  }
//
//
//   static void handleCrashAnalytics() {
//     const fatalError = true;
//
//     // Non-async exceptions
//     FlutterError.onError = (errorDetails) {
//       if (fatalError) {
//         // If you want to record a "fatal" exception
//         FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
//         // ignore: dead_code
//       } else {
//         // If you want to record a "non-fatal" exception
//         FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
//       }
//     };
//
//     // Async exceptions
//     PlatformDispatcher.instance.onError = (error, stack) {
//       if (fatalError) {
//         // If you want to record a "fatal" exception
//         FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
//         // ignore: dead_code
//       } else {
//         // If you want to record a "non-fatal" exception
//         FirebaseCrashlytics.instance.recordError(error, stack);
//       }
//       return true;
//     };
//   }
//
//
//   /* The notification system consists of two main classes:
//   LocalNotificationManager: Handles local notification configuration and display
//   HandleNotifications: Manages Firebase Cloud Messaging (FCM) integration

  static Future<void> initializeNotification() async {
    ///11. For Notifications

    await LocalNotificationManager.initialize();

  }
}
