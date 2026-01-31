import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';

class ZoomVideoSdkBootstrap {
  ZoomVideoSdkBootstrap._();

  static final ZoomVideoSdkBootstrap instance = ZoomVideoSdkBootstrap._();

  final ZoomVideoSdk _zoom = ZoomVideoSdk();

  bool _initialized = false;
  Future<void>? _initFuture;

  ZoomVideoSdk get zoom => _zoom;
  bool get isInitialized => _initialized;

  /// Call this from anywhere, it will only run init once.
  Future<void> ensureInitialized() {
    if (_initialized) return Future.value();
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      final initConfig = InitConfig(
        domain: "zoom.us",
        enableLog: kDebugMode,
      );

      final res = await _zoom.initSdk(initConfig);
      debugPrint("[ZoomVideoSDK] initSdk result: $res");

      _initialized = true;
    } on PlatformException catch (e) {
      final msg = (e.message ?? "").toLowerCase();
      final code = (e.code).toLowerCase();
      
      debugPrint(
          "[ZoomVideoSDK] initSdk PlatformException: code=${e.code}, message=${e.message}");

      // Zoom Video SDK error code 1 is "wrong usage", this commonly happens on duplicate init.
      // "sdkinit_failed" with message "Init SDK Failed" is also observed on Android when re-initializing (e.g. after hot restart).
      // Treat duplicate init as success so the app does not crash on hot restart or double calls.
      if (msg.contains("error code: 1") ||
          msg.contains("error code 1") ||
          msg.contains("wrong usage") ||
          msg.contains("already") ||
          msg.contains("init sdk failed") ||
          code == "sdkinit_failed") {
        debugPrint("[ZoomVideoSDK] Treating '$code: $msg' as 'Already Initialized' -> Success");
        _initialized = true;
        return;
      }

      // If initialization failed for another reason, reset the future so we can try again later.
      _initFuture = null;
      rethrow;
    } catch (e) {
       _initFuture = null;
       rethrow;
    }
  }
}
