import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scholarsgyanacademy/core/services/zoom_video_sdk_bootstrap.dart';

/// Result of Zoom session join attempt
class ZoomJoinResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final bool isWaitingForHost;

  const ZoomJoinResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.isWaitingForHost = false,
  });

  factory ZoomJoinResult.success({bool waitingForHost = false}) =>
      ZoomJoinResult(success: true, isWaitingForHost: waitingForHost);

  factory ZoomJoinResult.failure({required String message, String? code}) {
    return ZoomJoinResult(
      success: false,
      errorMessage: message,
      errorCode: code,
    );
  }
}

/// Zoom Video SDK Service abstraction
abstract class ZoomService {
  Future<void> initialize();

  Future<ZoomJoinResult> joinMeeting({
    required String sdkJwtToken,
    required String sessionName,
    required String userName,
  });

  Future<void> leaveMeeting();

  bool get isInMeeting;
  bool get isInSession;

  Future<void> dispose();
}

class ZoomServiceImpl implements ZoomService {
  ZoomServiceImpl();

  final ZoomVideoSdk _zoom = ZoomVideoSdkBootstrap.instance.zoom;

  bool _isInMeeting = false;
  bool _isJoining = false; // Prevent concurrent join attempts

  @override
  bool get isInMeeting => _isInMeeting;

  @override
  bool get isInSession => _isInMeeting;

  @override
  Future<void> initialize() async {
    await ZoomVideoSdkBootstrap.instance.ensureInitialized();
  }

  @override
  Future<ZoomJoinResult> joinMeeting({
    required String sdkJwtToken,
    required String sessionName,
    required String userName,
  }) async {
    // FIX #6: Prevent double joins with atomic lock
    if (_isJoining) {
      debugPrint(
        '[ZoomService] ⚠️ Join already in progress, ignoring duplicate request',
      );
      return ZoomJoinResult.failure(
        message: 'Join already in progress',
        code: 'JOIN_IN_PROGRESS',
      );
    }

    // FIX 1: Only block if truly in a different meeting (not during fresh join)
    if (_isInMeeting && !_isJoining) {
      debugPrint('[ZoomService] ! Already in a meeting');
      return ZoomJoinResult.failure(
        message: 'Already in a meeting',
        code: 'ALREADY_IN_MEETING',
      );
    }

    _isJoining = true;

    try {
      // Step 1: Request permissions (FIX #7: Android 12+ Bluetooth)
      debugPrint('[ZoomService] Requesting permissions...');
      final permissionsGranted = await _requestPermissions();

      if (!permissionsGranted) {
        debugPrint('[ZoomService] ❌ Required permissions denied');
        return ZoomJoinResult.failure(
          message: 'Camera and microphone permissions are required',
          code: 'PERMISSIONS_DENIED',
        );
      }

      // Step 2: Initialize SDK
      debugPrint('[ZoomService] Initializing SDK...');
      await initialize();

      // Step 3: Validate inputs
      if (sdkJwtToken.trim().isEmpty) {
        return ZoomJoinResult.failure(
          message: 'Invalid Zoom Video SDK token',
          code: 'INVALID_TOKEN',
        );
      }
      if (sessionName.trim().isEmpty) {
        return ZoomJoinResult.failure(
          message: 'Invalid session name',
          code: 'INVALID_SESSION_NAME',
        );
      }
      if (userName.trim().isEmpty) {
        return ZoomJoinResult.failure(
          message: 'Invalid user name',
          code: 'INVALID_USER_NAME',
        );
      }

      // Step 4: Check for active session and clean up if needed
      // FIX 1: Only cleanup if NOT currently joining (prevents auto-leave during fresh join)
      debugPrint('[ZoomService] Checking for active session...');
      if (!_isJoining) {
        final hasActiveSession = await _checkAndCleanupActiveSession();
        if (hasActiveSession) {
          debugPrint('[ZoomService] Cleaned up previous session');
        }
      } else {
        debugPrint('[ZoomService] Skipping cleanup check (currently joining)');
      }

      // Step 5: Configure and join
      debugPrint('[ZoomService] ========== JOIN CONFIGURATION ==========');
      debugPrint('[ZoomService] Session Name: "$sessionName"');
      debugPrint(
        '[ZoomService] User Name: "$userName"',
      ); // ✅ CRITICAL: Verify this shows actual name
      debugPrint('[ZoomService] Token Length: ${sdkJwtToken.length} chars');
      debugPrint('[ZoomService] ===========================================');

      final joinConfig = JoinSessionConfig(
        sessionName: sessionName,
        sessionPassword: '',
        token: sdkJwtToken,
        userName: userName, // ✅ CRITICAL: This MUST be actual student name
        audioOptions: {'connect': true, 'mute': false},
        videoOptions: {'localVideoOn': true},
        sessionIdleTimeoutMins: 40,
      );

      debugPrint('[ZoomService] Calling _zoom.joinSession()...');
      final joinResultCode = await _zoom.joinSession(joinConfig);
      debugPrint('[ZoomService] joinSession() returned: $joinResultCode');

      // Step 6: Validate join result
      final resultString = joinResultCode.toString().toLowerCase();
      final isSuccess =
          joinResultCode == Errors.Success || resultString.contains('success');

      if (isSuccess) {
        debugPrint(
          '[ZoomService] ✅ Join successful - setting _isInMeeting = true',
        );
        _isInMeeting = true;

        // FIX #8: Check if host has started (basic check)
        // Note: Full implementation would require event listeners
        final isWaiting = await _checkIfWaitingForHost();

        return ZoomJoinResult.success(waitingForHost: isWaiting);
      } else {
        debugPrint('[ZoomService] ❌ Join failed: $joinResultCode');
        return ZoomJoinResult.failure(
          message: 'Zoom joinSession failed: $joinResultCode',
          code: resultString,
        );
      }
    } on PlatformException catch (e) {
      debugPrint('[ZoomService] PlatformException: ${e.code} ${e.message}');

      // FIX #9: Detect network errors
      final isNetworkError = _isNetworkError(e);
      final message = isNetworkError
          ? 'Network connection failed. Please check your internet connection.'
          : 'Failed to join session: ${e.message ?? e.code}';

      return ZoomJoinResult.failure(message: message, code: e.code);
    } catch (e) {
      debugPrint('[ZoomService] Error: $e');
      return ZoomJoinResult.failure(
        message: 'Failed to join session: $e',
        code: 'EXCEPTION',
      );
    } finally {
      _isJoining = false;
    }
  }

  /// FIX #7: Request all required permissions including Android 12+ Bluetooth
  Future<bool> _requestPermissions() async {
    try {
      final permissions = <Permission>[
        Permission.camera,
        Permission.microphone,
      ];

      // Android 12+ (API 31+) requires additional Bluetooth permissions
      if (Platform.isAndroid) {
        permissions.addAll([
          Permission.bluetooth,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
        ]);
      }

      // Request all permissions
      final statuses = await permissions.request();

      // Check critical permissions (camera & microphone are mandatory)
      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

      // Bluetooth permissions are optional but recommended
      if (Platform.isAndroid) {
        final bluetoothGranted =
            statuses[Permission.bluetoothConnect]?.isGranted ?? false;
        if (!bluetoothGranted) {
          debugPrint(
            '[ZoomService] ⚠️ Bluetooth permissions not granted - audio routing may be limited',
          );
        }
      }

      return cameraGranted && micGranted;
    } catch (e) {
      debugPrint('[ZoomService] Error requesting permissions: $e');
      return false;
    }
  }

  /// FIX #6: Check for active session and clean up properly
  /// FIX 1: NEVER cleanup during active join
  Future<bool> _checkAndCleanupActiveSession() async {
    // CRITICAL: Never cleanup if we're currently joining
    if (_isJoining) {
      debugPrint('[ZoomService] Skipping cleanup - join in progress');
      return false;
    }

    try {
      final session = _zoom.session;
      final mySelf = await session.getMySelf();

      if (mySelf != null) {
        debugPrint('[ZoomService] Active session detected, leaving...');
        await _zoom.leaveSession(false);
        _isInMeeting = false;

        // Wait a bit for cleanup to complete
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      }
    } catch (e) {
      debugPrint('[ZoomService] No active session or error checking: $e');
    }
    return false;
  }

  /// FIX #8: Basic check if waiting for host
  Future<bool> _checkIfWaitingForHost() async {
    try {
      final remoteUsers = await _zoom.session.getRemoteUsers();
      final hasRemoteUsers = remoteUsers != null && remoteUsers.isNotEmpty;

      // If no remote users, might be waiting for host
      // This is a basic heuristic - full implementation needs event listeners
      return !hasRemoteUsers;
    } catch (e) {
      debugPrint('[ZoomService] Error checking for host: $e');
      return false;
    }
  }

  /// FIX #9: Detect network-related errors
  bool _isNetworkError(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();

    return code.contains('network') ||
        code.contains('connection') ||
        code.contains('timeout') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('internet');
  }

  @override
  Future<void> leaveMeeting() async {
    // FIX 4: CRITICAL GUARD - Never leave during join or if not in meeting
    if (_isJoining) {
      debugPrint('[ZoomService] ⚠️ Ignoring leave - join in progress');
      return;
    }

    if (!_isInMeeting) {
      debugPrint('[ZoomService] ⚠️ Ignoring leave - not in meeting');
      return;
    }

    try {
      debugPrint('[ZoomService] Leaving session...');
      if (!ZoomVideoSdkBootstrap.instance.isInitialized) {
        _isInMeeting = false;
        _isJoining = false;
        return;
      }

      await _zoom.leaveSession(false);
      _isInMeeting = false;
      _isJoining = false;
      debugPrint('[ZoomService] Left session');
    } catch (e) {
      debugPrint('[ZoomService] Error leaving: $e');
      _isInMeeting = false;
      _isJoining = false;
    }
  }

  @override
  Future<void> dispose() async {
    _isInMeeting = false;
    _isJoining = false;
  }
}
