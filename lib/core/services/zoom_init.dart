import 'package:flutter/material.dart';
import 'package:scholarsgyanacademy/core/services/zoom_video_sdk_bootstrap.dart';

class ZoomVideoSdkProvider extends StatefulWidget {
  const ZoomVideoSdkProvider({super.key, required this.child});

  final Widget child;

  @override
  State<ZoomVideoSdkProvider> createState() => _ZoomVideoSdkProviderState();
}

class _ZoomVideoSdkProviderState extends State<ZoomVideoSdkProvider> {
  @override
  void initState() {
    super.initState();

    // Trigger init once, do not crash app if it fails, just log.
    ZoomVideoSdkBootstrap.instance.ensureInitialized().catchError((e) {
      debugPrint("[ZoomVideoSDK] init failed in provider: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
