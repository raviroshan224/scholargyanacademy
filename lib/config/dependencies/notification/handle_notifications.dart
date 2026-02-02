import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notification_manager.dart';

class HandleNotifications {
  /// 8
  static final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  // static String defaultTopic = 'general';
  static String defaultTopic = 'testolp';

  ///8. Ways of sending notifications
  static Future<void> notificationMethods() async {
    // Request notification permissions (especially important for iOS)
    await firebaseMessaging.requestPermission();

    /// 8.1
    await tokenWiseNotification();

    /**
     * Method 2 : Topic Based
     * */
    // Only subscribe to topic after APNS token is available on iOS
    if (!Platform.isIOS) {
      subscribeToTopic(topicName: defaultTopic);
    } else {
      String? apnsToken = await firebaseMessaging.getAPNSToken();
      if (apnsToken != null) {
        subscribeToTopic(topicName: defaultTopic);
      }
    }
  }

  /// 8.1
  static Future<void> tokenWiseNotification() async {
    /**
     *   Method 1 : Token Based
     */

    if (Platform.isIOS) {
      // Wait for APNS token
      String? apnsToken = await firebaseMessaging.getAPNSToken();
      if (apnsToken == null) {
        // Optionally, retry or log warning
        print('[FCM] APNS token not available yet.');
        return;
      } else {
        print('[FCM] APNS token: $apnsToken');
      }
      // Now safe to get FCM token
      String? fcmToken = await firebaseMessaging.getToken();
      print('[FCM] FCM token (iOS): $fcmToken');
      // Send fcmToken to backend if needed
    } else {
      // Android: get FCM token directly
      String? fcmToken = await firebaseMessaging.getToken();
      print('[FCM] FCM token (Android): $fcmToken');
      // Send fcmToken to backend if needed
    }
  }

  /// 8.2
  static void subscribeToTopic({required String topicName}) {
    try{
      firebaseMessaging.subscribeToTopic(topicName);
    }catch(e){
      // print("Topic Error : ${e.toString()}");
    }
  }

  /// 8.3
  static Future<void> unSubscribeToTopic({required String topicName}) async {

    try{
      await firebaseMessaging.unsubscribeFromTopic(topicName);
    }
    catch(e){
      rethrow;
    }
  }


  /// 9
  static Future handleNotifications() async {

    ///  Works When App is in Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage? event) {

      /// 12

      var random = Random();
      var notificationID = random.nextInt(100); // Generates a number between 0 and 9 (inclusive)

      if (event?.notification != null) {

        if(Platform.isIOS){
          LocalNotificationManager.onDidReceiveLocalNotification(notificationID, event?.notification?.title, event?.notification?.body, '');
        }
        LocalNotificationManager.createNDisplayNotification(event);

      }



    });


    /// App is in Background and But not terminated

    /**
     * When an app is in the background and a notification is received,
     * the notification is handled by the system tray (also known as the notification drawer)
     * of the device's operating system.
     * */
    FirebaseMessaging.onMessageOpenedApp.listen((event) { });


    /// App is terminated
    FirebaseMessaging.instance.getInitialMessage().then((value) => {});

  }

  /// 10
  /// Register the background message handler in your HandleNotifications class
  static void registerBackgroundMessageHandler() {
    FirebaseMessaging.onBackgroundMessage(backgroundMsgHandler);
  }

  /// Handling Background Messages
  @pragma('vm:entry-point')
  static Future backgroundMsgHandler(RemoteMessage? remoteMessage) async {}



}



