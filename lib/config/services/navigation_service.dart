import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/features/auth/view/pages/login_page.dart';

// Unified NavigationService with queued actions to avoid repeated post-frame retries.
final navigationServiceProvider = Provider<NavigationService>((Ref ref) {
  return NavigationService();
});

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final List<VoidCallback> _queue = [];
  bool _flushing = false;
  bool _loginQueued = false;

  bool get isReady => navigatorKey.currentState != null;

  void _scheduleFlush() {
    if (_flushing) return;
    _flushing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushQueue();
    });
  }

  void _flushQueue() {
    if (!isReady) {
      _flushing = false;
      _scheduleFlush();
      return;
    }
    for (final action in List<VoidCallback>.from(_queue)) {
      action();
    }
    _queue.clear();
    _flushing = false;
    _loginQueued = false; // reset after any login navigation executed
  }

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) async {
    if (!isReady) {
      _queue.add(() {
        navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
      });
      _scheduleFlush();
      return Future.value();
    }
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  void navigateToLogin({String? errorMessage}) {
    if (_loginQueued) return; // prevent duplicate queue entries
    _loginQueued = true;
    _queue.add(() {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      if (errorMessage != null) {
        final ctx = navigatorKey.currentState!.context;
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    });
    _scheduleFlush();
  }
}
