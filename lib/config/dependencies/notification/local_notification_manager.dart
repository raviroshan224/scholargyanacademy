import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/core.dart';

class LocalNotificationManager {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

  static Future<void> initializePlatform() async {
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
      },
    );
  }

  static Future<void> requestPermission() async {
    if (Platform.isIOS) {
      await requestIOSPermission();
    } else if (Platform.isAndroid) {
      await requestAndroidPermission();
    }
  }

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

  static Future<void> requestAndroidPermission() async {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    int? sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }
}
