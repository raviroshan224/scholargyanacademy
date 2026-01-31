import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/core.dart';

class LocalNotificationManager {
  /// 5.b.a
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 7.a
  static NotificationDetails notificationDetails = const NotificationDetails();

  static String channelID = 'ScholarGyanGeneral';
  static String channelName = 'ScholarGyanGeneral';
  static String channelDescription =
      'Notifications from the ${AppStrings.appName}';

  static Future<void> initialize() async {
    try {
      await requestPermission();
      await initializePlatform();
    } catch (e, stackTrace) {
      debugPrint('LocalNotificationManager initialization failed: $e');
      debugPrint(stackTrace.toString());
    }
  }

  ///6
  static Future<void> initializePlatform() async {
    /// 6.a Initialing IOS Settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    /// 6.b Initialing Android
    const InitializationSettings initializationSettings =
        InitializationSettings(
      /// Use default launcher icon shipped with the app bundle
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: initializationSettingsIOS,
    );

    /// iii iOS Initialization

    /// iv
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationList()));
        // Get.to(() => NotificationList());
      },
    );

    /// 7 Add Notification Details
    await getNotificationDetails(null);
  }

  ///5. Requesting Permission
  static Future<void> requestPermission() async {
    if (Platform.isIOS) {
      await requestIOSPermission();
    } else if (Platform.isAndroid) {
      await requestAndroidPermission();
    }
  }

  ///5.a TODO Request IOS permission
  static Future<void> requestIOSPermission() async {
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()!
        .requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// 5.b
  static Future<void> requestAndroidPermission() async {
    /// This code is giving the android sdk version
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    int? sdkInt = androidInfo.version.sdkInt;

    /**
     * flutter_local_notifications handles permissions for notifications
     * when sdk>=33
     */
    if (sdkInt >= 33) {
      _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    /** On Android devices with an SDK level less than 33 (Android 12) by
     * requesting the necessary permissions automatically when you use the
     * show method to display a notification.
     */
  }

  /// 7
  /// RemoteMessage: Model for our Notifications

  static Future<NotificationDetails> getNotificationDetails(
      RemoteMessage? message) async {
    ///7.a
    notificationDetails = NotificationDetails(
        android: await androidNotificationDetails(message),
        iOS: await iosNotificationDetails(message));

    return notificationDetails;
  }

  /// 7.b
  ///

  static Future<AndroidNotificationDetails> androidNotificationDetails(
      RemoteMessage? message) async {
    String imageUrl = message?.notification?.android?.imageUrl ?? '';
    /* Uncomment below line if sound file is needed */
    // String soundFileName = message?.notification?.android?.sound ?? '';
    final String? imageData = await fetchImage(imageUrl);

    return AndroidNotificationDetails(
        //Channel ID,
        channelID,
        // Channel Name
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        fullScreenIntent: true,
        playSound: true,
        /*TODO For Sound in Notifications*/
        // sound: RawResourceAndroidNotificationSound(soundFileName),
        icon: 'ic_launcher',
        largeIcon: imageData != null
            ? ByteArrayAndroidBitmap.fromBase64String(imageData)
            : const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
        styleInformation: imageData != null
            ? BigPictureStyleInformation(
                ByteArrayAndroidBitmap.fromBase64String(imageData),
                largeIcon:
                    const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              )
            : null);
  }

  ///13
  static Future<void> createNDisplayNotification(RemoteMessage? message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notificationsPlugin.show(
        id,
        message?.notification?.title ?? '',
        message?.notification?.body ?? '',
        await getNotificationDetails(message),
        // await getNotificationDetails(message),
        payload: message?.data['_id'],
      );
    } on Exception catch (e) {
      throw Exception(e.toString());
    }
  }

  /// 14
  static Future<String?> fetchImage(String imageUrl) async {
    if (imageUrl.isEmpty) {
      return null;
    }
    try {
      final response = await Dio().get<Uint8List>(imageUrl,
          options: Options(responseType: ResponseType.bytes));

      final base64Image = base64Encode(response.data?.toList() ?? []);
      return base64Image;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> onDidReceiveLocalNotification(
      int notificationID, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notificationsPlugin.show(
        id,
        title ?? '',
        body ?? '',
        await getNotificationDetails(null),
        // await getNotificationDetails(message),
        //  payload: payload?.data['_id'],
      );
    } on Exception catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<DarwinNotificationDetails> iosNotificationDetails(
      RemoteMessage? message) async {
    String imageUrl = message?.notification?.apple?.imageUrl ?? '';

    List<DarwinNotificationAttachment> attachments = [];

    if (imageUrl.isNotEmpty) {
      try {
        // Download and save image for iOS notification
        final attachment = await createIOSImageAttachment(imageUrl);
        if (attachment != null) {
          attachments.add(attachment);
        }
      } catch (e) {
        print('Error creating iOS attachment: $e');
      }
    }

    // Customize your iOS notification details here
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: attachments,
      subtitle: AppStrings.notificationSubtitle,
    );
  }

  // Create iOS notification attachment
  static Future<DarwinNotificationAttachment?> createIOSImageAttachment(
      String imageUrl) async {
    try {
      final response = await Dio().get<Uint8List>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null) {
        // Create a temporary file
        final tempDir = Directory.systemTemp;
        final fileName =
            'notification_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');

        await file.writeAsBytes(response.data!);

        return DarwinNotificationAttachment(
          file.path,
          identifier: 'image',
        );
      }
    } catch (e) {
      print('Error downloading image for iOS notification: $e');
    }
    return null;
  }
}
