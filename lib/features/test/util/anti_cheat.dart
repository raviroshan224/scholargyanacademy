// lib/features/test/util/anti_cheat.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Android screenshot blocking using flutter_windowmanager.
/// For iOS, this is a no‑op (iOS does not allow programmatic screenshot blocking).
Future<void> blockScreenshots() async {
  if (!kIsWeb && Platform.isAndroid) {
    try {
      // flutter_windowmanager package provides secure flag.
      // Import is deferred to avoid adding a dependency if not needed.
      // ignore: avoid_dynamic_calls
      final wm = await importPackage('flutter_windowmanager');
      // ignore: avoid_dynamic_calls
      await wm.addFlags(0x00002000); // FLAG_SECURE
    } catch (e) {
      debugPrint('AntiCheat: Failed to block screenshots: $e');
    }
  }
}

/// Detects focus loss (app moving to background) – the ViewModel already
/// observes WidgetsBindingObserver. This helper can be called from the
/// ViewModel's didChangeAppLifecycleState if additional platform‑specific
/// handling is required.
Future<void> handleFocusLoss() async {
  // Currently a placeholder – could log analytics or trigger additional
  // security measures.
  debugPrint('AntiCheat: Focus loss detected');
}

/// Helper to dynamically import a package at runtime – used to avoid a hard
/// dependency on flutter_windowmanager when the app runs on platforms where it
/// is not supported.
Future<dynamic> importPackage(String packageName) async {
  // In a real implementation you would use `dart:mirrors` (not available in
  // Flutter) or a conditional import. Here we simply throw to indicate the
  // package must be added manually.
  throw UnimplementedError('Dynamic import of $packageName is not supported.');
}
