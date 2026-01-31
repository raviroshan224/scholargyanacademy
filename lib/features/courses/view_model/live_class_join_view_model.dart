import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
// Some files in this repo rely on the legacy provider symbols. Import legacy
// to ensure `StateNotifierProvider` is available for older provider signatures.
import 'package:flutter_riverpod/legacy.dart' as riverpod_legacy;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/zoom_service.dart';
import '../model/live_class_models.dart';
import '../service/live_class_service.dart';

enum LiveClassJoinStatus {
  idle,
  fetchingToken,
  requestingPermissions,
  joining,
  waitingForHost, // NEW: Zoom joined but host hasn't started meeting
  joined, // Host started, class is active
  failure,
}

class LiveClassJoinState {
  final LiveClassJoinStatus status;
  final String? errorMessage;
  final LiveClassJoinToken? token;
  final String? processingClassId;
  final bool hasJoinedOnce; // Prevent multiple join attempts

  const LiveClassJoinState({
    this.status = LiveClassJoinStatus.idle,
    this.errorMessage,
    this.token,
    this.processingClassId,
    this.hasJoinedOnce = false,
  });

  bool get isLoading =>
      status == LiveClassJoinStatus.fetchingToken ||
      status == LiveClassJoinStatus.requestingPermissions ||
      status == LiveClassJoinStatus.joining;

  bool get isWaitingForHost => status == LiveClassJoinStatus.waitingForHost;

  bool get isInMeeting =>
      status == LiveClassJoinStatus.joined ||
      status == LiveClassJoinStatus.waitingForHost;

  bool isProcessingClass(String classId) =>
      processingClassId == classId && (isLoading || isInMeeting);

  LiveClassJoinState copyWith({
    LiveClassJoinStatus? status,
    String? errorMessage,
    bool clearError = false,
    LiveClassJoinToken? token,
    bool clearToken = false,
    String? processingClassId,
    bool clearProcessingClass = false,
    bool? hasJoinedOnce,
  }) {
    return LiveClassJoinState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      token: clearToken ? null : (token ?? this.token),
      processingClassId: clearProcessingClass
          ? null
          : (processingClassId ?? this.processingClassId),
      hasJoinedOnce: hasJoinedOnce ?? this.hasJoinedOnce,
    );
  }

  static LiveClassJoinState initial() => const LiveClassJoinState();
}

class LiveClassJoinViewModel extends StateNotifier<LiveClassJoinState> {
  LiveClassJoinViewModel(this._service, this._zoomService)
      : super(LiveClassJoinState.initial());
  final LiveClassService _service;
  final ZoomService _zoomService;

  // FIX #4: Atomic lock to prevent race conditions
  bool _isJoining = false;
  DateTime? _lastJoinAttempt;
  static const _joinDebounceMs = 1000; // 1 second debounce

  /// Main entry point to join a live class
  /// Returns the token if successful, null otherwise.
  /// Caller is responsible for navigation to MeetingPage.
  Future<LiveClassJoinToken?> joinLiveClass(String classId) async {
    // FIX #4: Multi-layer race condition prevention
    
    // Layer 1: Check if already in a meeting
    if (state.hasJoinedOnce || state.isInMeeting) {
      print('⚠️ [JOIN FLOW] Already joined or in meeting, ignoring duplicate call');
      return null;
    }

    // Layer 2: Atomic lock check
    if (_isJoining) {
      print('⚠️ [JOIN FLOW] Join already in progress (atomic lock), ignoring');
      return null;
    }

    // Layer 3: Debounce rapid taps
    final now = DateTime.now();
    if (_lastJoinAttempt != null) {
      final timeSinceLastAttempt = now.difference(_lastJoinAttempt!).inMilliseconds;
      if (timeSinceLastAttempt < _joinDebounceMs) {
        print('⚠️ [JOIN FLOW] Debounced: ${timeSinceLastAttempt}ms since last attempt');
        return null;
      }
    }

    // Set atomic lock and timestamp
    _isJoining = true;
    _lastJoinAttempt = now;

    try {
      print('🔵 [JOIN FLOW] Starting join preparation for classId=$classId');
      state = state.copyWith(
        status: LiveClassJoinStatus.fetchingToken,
        clearError: true,
        processingClassId: classId,
      );

      // Step 1: Get join token from backend
      final tokenResult = await _service.getJoinToken(classId);
      if (tokenResult.isLeft) {
        print('❌ [JOIN FLOW] Token fetch failed: ${tokenResult.left.message}');
        _setFailure(tokenResult.left.message);
        return null;
      }

      final token = tokenResult.right;
      state = state.copyWith(token: token);

      // Step 2: Request permissions
      state = state.copyWith(status: LiveClassJoinStatus.requestingPermissions);
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print('❌ [JOIN FLOW] Permissions denied');
        _setFailure('Camera and microphone permissions are required');
        return null;
      }

      // Step 3: Set state to joining
      print('🔵 [JOIN FLOW] Token and permissions ready - setting state to joining');
      state = state.copyWith(
        status: LiveClassJoinStatus.joining,
        hasJoinedOnce: false, 
      );
      
      print('✅ [JOIN FLOW] Ready for join. Returning token to UI.');
      return token;
    } catch (e) {
      print('❌ [JOIN FLOW] Exception: $e');
      _setFailure(e.toString());
      return null;
    } finally {
      // Always release the atomic lock
      _isJoining = false;
    }
  }

  /// Called by MeetingPage after successful join
  void markAsJoined({bool waitingForHost = false}) {
    print('✅ [JOIN FLOW] Marked as joined (waitingForHost=$waitingForHost)');
    state = state.copyWith(
      status: waitingForHost 
        ? LiveClassJoinStatus.waitingForHost 
        : LiveClassJoinStatus.joined,
      hasJoinedOnce: true,
    );
  }

  /// Request camera and microphone permissions
  Future<bool> _requestPermissions() async {
    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

      return cameraGranted && micGranted;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings for permission management
  Future<void> openAppSettingsRequest() async {
    // Calls permission_handler's openAppSettings
    try {
      await openAppSettings();
    } catch (_) {
      // ignore errors when opening settings
    }
  }

  /// Leave current meeting
  Future<void> leaveMeeting() async {
    await _zoomService.leaveMeeting();
    reset();
  }

  /// Reset state
  void reset() {
    state = LiveClassJoinState.initial();
  }

  void _setFailure(String message) {
    state = state.copyWith(
      status: LiveClassJoinStatus.failure,
      errorMessage: message,
      clearProcessingClass: true,
      clearToken: true,
    );
  }
}

final liveClassJoinViewModelProvider = riverpod_legacy.StateNotifierProvider<
    LiveClassJoinViewModel, LiveClassJoinState>((ref) {
  final service = ref.read(liveClassServiceProvider);
  final zoomService = ref.read(zoomServiceProvider);
  return LiveClassJoinViewModel(service, zoomService);
});

/// Provide a ZoomService implementation. Tests can override this provider
/// to inject a mock implementation.
final zoomServiceProvider = Provider<ZoomService>((ref) {
  return ZoomServiceImpl();
});
