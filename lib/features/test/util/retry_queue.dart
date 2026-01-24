// lib/features/test/util/retry_queue.dart

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Represents a pending PATCH request.
class _PendingPatch {
  final Future<void> Function() execute;
  int attempt;
  _PendingPatch(this.execute) : attempt = 0;
}

/// Simple in‑memory retry queue.
///
/// - Stores pending PATCH requests when offline.
/// - Retries with exponential back‑off up to [maxAttempts].
/// - Flushes automatically when connectivity is restored (listen to
///   [ConnectivityProvider] or call [flush] manually).
class RetryQueue {
  final int maxAttempts;
  final Duration baseDelay;
  final List<_PendingPatch> _queue = [];
  bool _isFlushing = false;

  RetryQueue({this.maxAttempts = 3, this.baseDelay = const Duration(seconds: 2)});

  /// Add a PATCH request to the queue.
  void enqueue(Future<void> Function() request) {
    _queue.add(_PendingPatch(request));
    _scheduleFlush();
  }

  /// Attempt to flush the queue.
  Future<void> flush() async {
    if (_isFlushing) return;
    _isFlushing = true;
    while (_queue.isNotEmpty) {
      final pending = _queue.first;
      try {
        await pending.execute();
        _queue.removeAt(0);
      } catch (e) {
        pending.attempt++;
        if (pending.attempt >= maxAttempts) {
          // Give up after max attempts – drop the request and log.
          debugPrint('RetryQueue: dropping request after $maxAttempts attempts: $e');
          _queue.removeAt(0);
        } else {
          // Wait exponential back‑off before next attempt.
          final delay = baseDelay * (1 << (pending.attempt - 1));
          await Future.delayed(delay);
        }
      }
    }
    _isFlushing = false;
  }

  void _scheduleFlush() {
    // In a real app you would listen to connectivity changes.
    // Here we simply schedule a microtask to attempt flush.
    scheduleMicrotask(() => flush());
  }
}
